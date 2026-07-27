# =========================
# Imports
# =========================
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse
import shutil
import os
import uuid
import logging

# Main Model
from main_model.inference import predict_audio

# Custom Sounds
from custom_sounds.inference import extract_embedding
from custom_sounds.similarity import find_match
from custom_sounds.firestore_db import save_embedding, load_user_sounds, delete_sound

# =========================
# App
# =========================
app = FastAPI(
    title="HeAra Combined API",
    version="1.0"
)

# =========================
# Logging
# =========================
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("heara-combined")

# =========================
# Allowed extensions
# =========================
ALLOWED_EXT = (".wav", ".mp3", ".ogg")


# =========================
# Health check
# =========================
@app.get("/")
def home():
    return {
        "status": "running",
        "message": "HeAra Combined API is live 🚀"
    }


# =========================================================
# MAIN MODEL ENDPOINT
# =========================================================
@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    filename = file.filename.lower()

    if not filename.endswith(ALLOWED_EXT):
        raise HTTPException(
            status_code=400,
            detail="Only audio files (.wav, .mp3, .ogg) allowed"
        )

    temp_file = f"temp_{uuid.uuid4()}.wav"

    try:
        logger.info(f"[Main Model] Received: {file.filename}")

        with open(temp_file, "wb") as f:
            shutil.copyfileobj(file.file, f)

        result = predict_audio(temp_file, use_decision=True)

        if result is None:
            raise HTTPException(status_code=500, detail="Prediction failed")

        logger.info(f"[Main Model] Result: {result}")

        return JSONResponse(content={
            "success": True,
            "label": str(result["label"]),
            "confidence": float(result["confidence"]),
            "alert": result.get("alert", False),
            "final_label": result.get("final_label", result["label"])
        })

    except HTTPException as he:
        raise he

    except Exception as e:
        logger.error(f"[Main Model] Error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

    finally:
        if os.path.exists(temp_file):
            os.remove(temp_file)


# =========================================================
# CUSTOM SOUNDS ENDPOINTS
# =========================================================
@app.post("/custom/register")
async def register_sound(
    file: UploadFile = File(...),
    user_id: str = Form(...),
    label: str = Form(...)
):
    if not file.filename.lower().endswith(ALLOWED_EXT):
        raise HTTPException(status_code=400, detail="Only .wav .mp3 .ogg allowed")

    temp_file = f"temp_{uuid.uuid4()}.wav"

    try:
        logger.info(f"[Custom Sounds] Registering: user={user_id}, label={label}")

        with open(temp_file, "wb") as f:
            shutil.copyfileobj(file.file, f)

        embedding = extract_embedding(temp_file)
        save_embedding(user_id, label, embedding)

        user_sounds = load_user_sounds(user_id)
        existing = next((s for s in user_sounds if s["label"] == label), None)
        total = len(existing["embeddings"]) if existing else 1

        logger.info(f"[Custom Sounds] ✅ Registered: {label} for user {user_id}")

        return JSONResponse(content={
            "success": True,
            "label": label,
            "total_recordings": total
        })

    except Exception as e:
        logger.error(f"[Custom Sounds] Error: {str(e)}")
        raise HTTPException(status_code=500, detail="Registration failed")

    finally:
        if os.path.exists(temp_file):
            os.remove(temp_file)


@app.post("/custom/predict")
async def predict_custom(
    file: UploadFile = File(...),
    user_id: str = Form(...)
):
    if not file.filename.lower().endswith(ALLOWED_EXT):
        raise HTTPException(status_code=400, detail="Only .wav .mp3 .ogg allowed")

    temp_file = f"temp_{uuid.uuid4()}.wav"

    try:
        logger.info(f"[Custom Sounds] Predicting for user={user_id}")

        user_sounds = load_user_sounds(user_id)

        logger.info(f"[Custom Sounds] Loaded sounds: {[s['label'] for s in user_sounds]}")

        if not user_sounds:
            raise HTTPException(status_code=404, detail="No custom sounds registered for this user")

        with open(temp_file, "wb") as f:
            shutil.copyfileobj(file.file, f)

        embedding = extract_embedding(temp_file)
        result = find_match(embedding, user_sounds)

        logger.info(f"[Custom Sounds] Result: {result}")

        return JSONResponse(content={
            "success": True,
            "matched": result["matched"],
            "label": result["label"],
            "similarity": result["similarity"]
        })

    except HTTPException as he:
        raise he

    except Exception as e:
        logger.error(f"[Custom Sounds] Error: {str(e)}")
        raise HTTPException(status_code=500, detail="Prediction failed")

    finally:
        if os.path.exists(temp_file):
            os.remove(temp_file)


@app.delete("/custom/delete")
async def delete_custom_sound(
    user_id: str = Form(...),
    label: str = Form(...)
):
    try:
        delete_sound(user_id, label)
        return JSONResponse(content={
            "success": True,
            "message": f"'{label}' deleted successfully"
        })
    except Exception as e:
        logger.error(f"[Custom Sounds] Error: {str(e)}")
        raise HTTPException(status_code=500, detail="Delete failed")