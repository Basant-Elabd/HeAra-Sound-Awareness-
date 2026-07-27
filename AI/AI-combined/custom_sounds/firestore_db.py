# =========================
# Imports
# =========================
import firebase_admin
from firebase_admin import credentials, firestore
import numpy as np
import os
from typing import List, Dict
from datetime import datetime, timezone

# =========================
# Init Firebase
# =========================
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CRED_PATH = os.path.join(BASE_DIR, "..", "heara-3041c-firebase-adminsdk-fbsvc-69c169eb73.json")
if not firebase_admin._apps:
    cred = credentials.Certificate(CRED_PATH)
    firebase_admin.initialize_app(cred)

db = firestore.client()

# =========================
# Save embedding to Firestore
# =========================
def save_embedding(user_id: str, label: str, embedding: np.ndarray):
    """
    كل embedding بيتحفظ كـ document منفصل
    custom_sounds → user_id → sounds → label → recordings → doc
    """
    label_ref = (
        db.collection("custom_sounds")
          .document(user_id)
          .collection("sounds")
          .document(label)
    )

    # نتأكد إن document الـ label نفسه موجود فعلياً (مش ضمني بس)
    label_ref.set({
        "label": label,
        "updated_at": datetime.now(timezone.utc).isoformat()
    }, merge=True)

    recordings_ref = label_ref.collection("recordings")
    recordings_ref.add({
        "embedding": embedding.tolist()
    })

# =========================
# Load all sounds for a user
# =========================
def load_user_sounds(user_id: str) -> List[Dict]:
    sounds_ref = (
        db.collection("custom_sounds")
          .document(user_id)
          .collection("sounds")
    )

    result = []
    for sound_doc in sounds_ref.stream():
        label = sound_doc.id
        recordings = sound_doc.reference.collection("recordings").stream()
        embeddings = [
            np.array(r.to_dict()["embedding"])
            for r in recordings
        ]
        if embeddings:
            result.append({"label": label, "embeddings": embeddings})

    return result

# =========================
# Delete a sound
# =========================
def delete_sound(user_id: str, label: str):
    sound_ref = (
        db.collection("custom_sounds")
          .document(user_id)
          .collection("sounds")
          .document(label)
    )
    # حذف الـ recordings الأول
    for rec in sound_ref.collection("recordings").stream():
        rec.reference.delete()
    # بعدين حذف الـ document نفسه
    sound_ref.delete()