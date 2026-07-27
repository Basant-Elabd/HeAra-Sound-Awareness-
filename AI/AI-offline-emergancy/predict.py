import numpy as np
import librosa
import joblib
import tensorflow as tf

# =========================
# LOAD MODELS
# =========================
emergency_model = tf.keras.models.load_model(
    "artifacts/emergency_model.h5"
)

emergency_scaler = joblib.load(
    "artifacts/scaler.pkl"
)

type_model = tf.keras.models.load_model(
    "artifacts/type_model.h5"
)

type_scaler = joblib.load(
    "artifacts/type_scaler.pkl"
)

type_encoder = joblib.load(
    "artifacts/type_encoder.pkl"
)

# =========================
# SETTINGS
# =========================
SAMPLE_RATE = 16000
THRESHOLD = 0.3

# =========================
# BASIC FEATURES
# =========================
def extract_basic_features(audio, sr):

    mfcc = librosa.feature.mfcc(
        y=audio,
        sr=sr,
        n_mfcc=13
    )

    mfcc_mean = np.mean(mfcc.T, axis=0)
    mfcc_std = np.std(mfcc.T, axis=0)

    zcr = np.mean(
        librosa.feature.zero_crossing_rate(audio)
    )

    centroid = np.mean(
        librosa.feature.spectral_centroid(
            y=audio,
            sr=sr
        )
    )

    rms = np.mean(
        librosa.feature.rms(y=audio)
    )

    return np.concatenate([
        mfcc_mean,
        mfcc_std,
        [zcr, centroid, rms]
    ])

# =========================
# TYPE FEATURES
# =========================
def extract_type_features(audio, sr):

    target_len = sr * 3

    if len(audio) < target_len:
        audio = np.pad(
            audio,
            (0, target_len - len(audio))
        )
    else:
        audio = audio[:target_len]

    audio = audio / (
        np.max(np.abs(audio)) + 1e-9
    )

    chunk_size = len(audio) // 4

    features_list = []

    for i in range(4):

        chunk = audio[
            i * chunk_size:(i + 1) * chunk_size
        ]

        mfcc = librosa.feature.mfcc(
            y=chunk,
            sr=sr,
            n_mfcc=20
        )

        mfcc_mean = np.mean(mfcc, axis=1)
        mfcc_std = np.std(mfcc, axis=1)

        delta = librosa.feature.delta(mfcc)
        delta_mean = np.mean(delta, axis=1)

        zcr = np.mean(
            librosa.feature.zero_crossing_rate(chunk)
        )

        centroid = np.mean(
            librosa.feature.spectral_centroid(
                y=chunk,
                sr=sr
            )
        )

        bandwidth = np.mean(
            librosa.feature.spectral_bandwidth(
                y=chunk,
                sr=sr
            )
        )

        rolloff = np.mean(
            librosa.feature.spectral_rolloff(
                y=chunk,
                sr=sr
            )
        )

        rms = np.mean(
            librosa.feature.rms(y=chunk)
        )

        rolloff_ratio = (
            rolloff /
            (centroid + 1e-6)
        )

        features = np.concatenate([
            mfcc_mean,
            mfcc_std,
            delta_mean,
            [
                zcr,
                centroid,
                bandwidth,
                rolloff,
                rolloff_ratio,
                rms
            ]
        ])

        features_list.append(features)

    features_list = np.array(features_list)

    return np.concatenate([
        np.mean(features_list, axis=0),
        np.std(features_list, axis=0)
    ])

# =========================
# PIPELINE
# =========================
def predict_audio(file_path):

    audio, sr = librosa.load(
        file_path,
        sr=SAMPLE_RATE
    )

    # =====================
    # EMERGENCY
    # =====================
    feat = extract_basic_features(
        audio,
        sr
    )

    feat = emergency_scaler.transform(
        [feat]
    )

    emergency_prob = (
        emergency_model.predict(
            feat,
            verbose=0
        )[0][0]
    )

    print(
        "Emergency probability:",
        emergency_prob
    )

    if emergency_prob < THRESHOLD:
        return {
            "status": "Normal",
            "type": None
        }

    # =====================
    # TYPE
    # =====================
    type_feat = extract_type_features(
        audio,
        sr
    )

    type_feat = type_scaler.transform(
        [type_feat]
    )

    probs = type_model.predict(
        type_feat,
        verbose=0
    )

    class_id = np.argmax(probs)

    label = type_encoder.inverse_transform(
        [class_id]
    )[0]

    confidence = float(
        np.max(probs)
    )

    return {
        "status": "Emergency",
        "type": label,
        "confidence": round(confidence, 4)
    }

# =========================
# TEST
# =========================
if __name__ == "__main__":

    result = predict_audio(
        "test.wav"
    )

    print(result)