import tensorflow as tf

# =========================
# Emergency Model
# =========================
emergency_model = tf.keras.models.load_model(
    "artifacts/emergency_model.h5"
)

converter = tf.lite.TFLiteConverter.from_keras_model(
    emergency_model
)

tflite_model = converter.convert()

with open(
    "artifacts/emergency_model.tflite",
    "wb"
) as f:
    f.write(tflite_model)

print("✅ Emergency TFLite Saved")


# =========================
# Type Model
# =========================
type_model = tf.keras.models.load_model(
    "artifacts/type_model.h5"
)

converter = tf.lite.TFLiteConverter.from_keras_model(
    type_model
)

tflite_model = converter.convert()

with open(
    "artifacts/type_model.tflite",
    "wb"
) as f:
    f.write(tflite_model)

print("✅ Type TFLite Saved")