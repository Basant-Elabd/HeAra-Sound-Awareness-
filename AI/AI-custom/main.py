# =========================
# Imports
# =========================
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse
import shutil
import os
import uuid
import logging

from inference import extract_embedding
from similarity import find_match
from firestore_db import save_embedding, load_user_sounds, delete_sound

# =========================
# App
# =========================
app = FastAPI(
    title="HeAra Custom Sounds API",
    version="1.0"
)

# =========================
# Logging
# =========================
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("heara-custom")

# =========================
# Allowed extensions
# =========================
ALLOWED_EXT = (".wav", ".mp3", ".ogg")

# =========================
# Health check
# =========================
@app.get("/")
def home():
    return {"status": "running", "message": "HeAra Custom Sounds API 🚀"}

# =========================
# Register new sound
# =========================
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
        logger.info(f"Registering sound: user={user_id}, label={label}")

        with open(temp_file, "wb") as f:
            shutil.copyfileobj(file.file, f)

        embedding = extract_embedding(temp_file)

        # حفظ في Firestore
        save_embedding(user_id, label, embedding)

        # عدد الـ recordings الحالية
        user_sounds = load_user_sounds(user_id)
        existing = next((s for s in user_sounds if s["label"] == label), None)
        total = len(existing["embeddings"]) if existing else 1

        logger.info(f"✅ Registered: {label} for user {user_id}")

        return JSONResponse(content={
            "success": True,
            "label": label,
            "total_recordings": total
        })

    except Exception as e:
        logger.error(f"Error: {str(e)}")
        raise HTTPException(status_code=500, detail="Registration failed")

    finally:
        if os.path.exists(temp_file):
            os.remove(temp_file)

# =========================
# Predict against custom sounds
# =========================
@app.post("/custom/predict")
async def predict_custom(
    file: UploadFile = File(...),
    user_id: str = Form(...)
):
    if not file.filename.lower().endswith(ALLOWED_EXT):
        raise HTTPException(status_code=400, detail="Only .wav .mp3 .ogg allowed")

    temp_file = f"temp_{uuid.uuid4()}.wav"

    try:
        logger.info(f"Predicting for user={user_id}")

        user_sounds = load_user_sounds(user_id)

        # DEBUG
        logger.info(f"Loaded sounds: {[s['label'] for s in user_sounds]}")
        logger.info(f"Total sounds: {len(user_sounds)}")

        if not user_sounds:
            raise HTTPException(status_code=404, detail="No custom sounds registered for this user")

        with open(temp_file, "wb") as f:
            shutil.copyfileobj(file.file, f)

        embedding = extract_embedding(temp_file)
        result = find_match(embedding, user_sounds)

        logger.info(f"Result: {result}")

        return JSONResponse(content={
            "success": True,
            "matched": result["matched"],
            "label": result["label"],
            "similarity": result["similarity"]
        })

    except HTTPException as he:
        raise he

    except Exception as e:
        logger.error(f"Error: {str(e)}")
        raise HTTPException(status_code=500, detail="Prediction failed")

    finally:
        if os.path.exists(temp_file):
            os.remove(temp_file)

# =========================
# Delete a sound
# =========================
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
        logger.error(f"Error: {str(e)}")
        raise HTTPException(status_code=500, detail="Delete failed")