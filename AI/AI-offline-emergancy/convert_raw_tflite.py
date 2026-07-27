import tensorflow as tf

# Emergency Model
emergency_model_raw = tf.keras.models.load_model("artifacts/emergency_model_raw.h5")
converter = tf.lite.TFLiteConverter.from_keras_model(emergency_model_raw)
tflite_model = converter.convert()

with open("artifacts/emergency_model_raw.tflite", "wb") as f:
    f.write(tflite_model)

print("✅ Emergency Raw TFLite Saved")

# Type Model
type_model_raw = tf.keras.models.load_model("artifacts/type_model_raw.h5")
converter = tf.lite.TFLiteConverter.from_keras_model(type_model_raw)
tflite_model = converter.convert()

with open("artifacts/type_model_raw.tflite", "wb") as f:
    f.write(tflite_model)

print("✅ Type Raw TFLite Saved")