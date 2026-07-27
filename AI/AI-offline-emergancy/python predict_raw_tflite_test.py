import numpy as np
import librosa
import joblib
import tensorflow as tf

# =========================
# LOAD TFLITE MODELS
# =========================
emergency_interpreter = tf.lite.Interpreter(
    model_path="artifacts/emergency_model_raw.tflite"
)
emergency_interpreter.allocate_tensors()

type_interpreter = tf.lite.Interpreter(
    model_path="artifacts/type_model_raw.tflite"
)
type_interpreter.allocate_tensors()

type_encoder = joblib.load("artifacts/type_encoder_raw.pkl")

SAMPLE_RATE = 16000
DURATION = 3
TARGET_LEN = SAMPLE_RATE * DURATION
THRESHOLD = 0.3


def load_raw_audio(file_path):
    audio, sr = librosa.load(file_path, sr=SAMPLE_RATE)

    if len(audio) < TARGET_LEN:
        audio = np.pad(audio, (0, TARGET_LEN - len(audio)))
    else:
        audio = audio[:TARGET_LEN]

    max_val = np.max(np.abs(audio))
    if max_val == 0:
        max_val = 1e-9
    audio = audio / max_val

    return audio.astype(np.float32)


def run_tflite(interpreter, input_data):
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    interpreter.set_tensor(
        input_details[0]['index'],
        input_data.astype(np.float32)
    )
    interpreter.invoke()

    return interpreter.get_tensor(output_details[0]['index'])


def predict_audio_raw_tflite(file_path):
    audio = load_raw_audio(file_path)
    audio = audio.reshape(1, TARGET_LEN, 1)

    emergency_prob = run_tflite(emergency_interpreter, audio)[0][0]
    print("Emergency probability (Raw TFLite):", emergency_prob)

    if emergency_prob < THRESHOLD:
        return {"status": "Normal", "type": None}

    probs = run_tflite(type_interpreter, audio)
    class_id = np.argmax(probs)
    label = type_encoder.inverse_transform([class_id])[0]
    confidence = float(np.max(probs))

    return {
        "status": "Emergency",
        "type": label,
        "confidence": round(confidence, 4)
    }


if __name__ == "__main__":
    result = predict_audio_raw_tflite("test.wav")
    print(result)