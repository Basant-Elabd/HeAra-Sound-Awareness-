# =========================
# Imports
# =========================
import numpy as np
import librosa
import tensorflow as tf
import tensorflow_hub as hub
from transformers import Wav2Vec2Processor, Wav2Vec2Model
import torch

# =========================
# Constants
# =========================
SAMPLE_RATE = 16000
DURATION = 5
TARGET_LEN = SAMPLE_RATE * DURATION

# =========================
# YAMNet lazy load
# =========================
yamnet_model = None

def get_yamnet():
    global yamnet_model
    if yamnet_model is None:
        print("Loading YAMNet...")
        yamnet_model = hub.load("https://tfhub.dev/google/yamnet/1")
        print("✅ YAMNet loaded")
    return yamnet_model

# =========================
# wav2vec2 lazy load
# =========================
processor = None
wav2vec_model = None

def get_wav2vec():
    global processor, wav2vec_model
    if wav2vec_model is None:
        print("Loading wav2vec2...")
        processor = Wav2Vec2Processor.from_pretrained("facebook/wav2vec2-base")
        wav2vec_model = Wav2Vec2Model.from_pretrained("facebook/wav2vec2-base")
        wav2vec_model.eval()
        print("✅ wav2vec2 loaded")
    return processor, wav2vec_model

# =========================
# Preprocessing
# =========================
def preprocess_audio(file_path: str):
    audio, sr = librosa.load(file_path, sr=SAMPLE_RATE)

    if len(audio) < TARGET_LEN:
        audio = np.pad(audio, (0, TARGET_LEN - len(audio)))
    else:
        audio = audio[:TARGET_LEN]

    return audio.astype(np.float32)

# =========================
# YAMNet embedding (512d)
# =========================
def get_yamnet_embedding(audio: np.ndarray) -> np.ndarray:
    yamnet = get_yamnet()
    scores, embeddings, log_mel = yamnet(audio)
    return np.mean(embeddings.numpy(), axis=0)  # (512,)

# =========================
# wav2vec2 embedding (768d)
# =========================
def get_wav2vec_embedding(audio: np.ndarray) -> np.ndarray:
    proc, model = get_wav2vec()
    inputs = proc(audio, sampling_rate=SAMPLE_RATE, return_tensors="pt", padding=True)

    with torch.no_grad():
        outputs = model(**inputs)

    # Mean pooling
    embedding = outputs.last_hidden_state.mean(dim=1).squeeze().numpy()
    return embedding  # (768,)

# =========================
# Combined embedding (1280d)
# =========================
def extract_embedding(file_path: str) -> np.ndarray:
    audio = preprocess_audio(file_path)

    yamnet_emb = get_yamnet_embedding(audio)      # (512,)
    wav2vec_emb = get_wav2vec_embedding(audio)    # (768,)

    combined = np.concatenate([yamnet_emb, wav2vec_emb])  # (1280,)
    return combined.astype(np.float32)