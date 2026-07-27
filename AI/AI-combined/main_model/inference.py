# =========================
# Imports
# =========================
import os
import numpy as np
import librosa
import tensorflow as tf
import tensorflow_hub as hub
import openl3
import joblib

from main_model.core_engine import should_alert

# =========================
# Paths
# =========================
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

MODEL_PATH = os.path.join(BASE_DIR, "artifacts", "model.h5")
SCALER_PATH = os.path.join(BASE_DIR, "artifacts", "scaler.pkl")
ENCODER_PATH = os.path.join(BASE_DIR, "artifacts", "label_encoder.pkl")

# =========================
# Load once
# =========================
model = tf.keras.models.load_model(MODEL_PATH)
scaler = joblib.load(SCALER_PATH)
le = joblib.load(ENCODER_PATH)

print("✅ Model loaded")


# =========================
# VGGish lazy load
# =========================
vggish_model = None

def get_vggish():
    global vggish_model
    if vggish_model is None:
        vggish_model = hub.load("https://tfhub.dev/google/vggish/1")
    return vggish_model


# =========================
# Constants
# =========================
SAMPLE_RATE = 16000
DURATION = 5
TARGET_LEN = SAMPLE_RATE * DURATION


# =========================
# Feature extraction
# =========================
def extract_features(audio, sr):

    audio = np.asarray(audio, dtype=np.float32)

    if len(audio) < TARGET_LEN:
        audio = np.pad(audio, (0, TARGET_LEN - len(audio)))
    else:
        audio = audio[:TARGET_LEN]

    vggish = get_vggish()
    vggish_emb = vggish(audio)
    vggish_feat = tf.reduce_mean(vggish_emb, axis=0).numpy()

    try:
        emb, _ = openl3.get_audio_embedding(
            audio,
            sr,
            content_type="env",
            input_repr="mel256",
            embedding_size=512
        )
        openl3_feat = np.mean(emb, axis=0)
    except:
        openl3_feat = np.zeros(512)

    return np.concatenate([vggish_feat, openl3_feat]).astype(np.float32)


# =========================
# Prediction (API ready)
# =========================
def predict_audio(file_path: str, use_decision: bool = False):

    try:
        audio, sr = librosa.load(file_path, sr=SAMPLE_RATE)

        features = extract_features(audio, sr)
        features = scaler.transform([features])

        pred = model.predict(features, verbose=0)

        class_id = int(np.argmax(pred))
        label = str(le.inverse_transform([class_id])[0])
        confidence = float(np.max(pred))

        result = {
            "label": label,
            "confidence": round(confidence, 4)
        }

        if use_decision:
            alert, final_label = should_alert(label, confidence)
            result["alert"] = alert
            result["final_label"] = final_label

        return result

    except Exception as e:
        print(f"❌ Error: {e}")
        return None