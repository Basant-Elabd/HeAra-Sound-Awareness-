# =========================
# Imports
# =========================
import numpy as np
from typing import List, Dict, Optional

# =========================
# Constants
# =========================
SIMILARITY_THRESHOLD = 0.70

# =========================
# Cosine Similarity
# =========================
def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    a = a / (np.linalg.norm(a) + 1e-9)
    b = b / (np.linalg.norm(b) + 1e-9)
    return float(np.dot(a, b))

# =========================
# Compare against stored embeddings
# =========================
def find_match(
    query_embedding: np.ndarray,
    stored_sounds: List[Dict],
    threshold: float = SIMILARITY_THRESHOLD
) -> Optional[Dict]:
    """
    stored_sounds: list of dicts, each has:
        - label: str
        - embeddings: List[np.ndarray]  (كل الـ recordings للصوت ده)
    
    Returns best match or None
    """
    best_score = -1
    best_label = None

    for sound in stored_sounds:
        label = sound["label"]
        embeddings = sound["embeddings"]

        # Average embedding للـ recordings دي كلها
        avg_embedding = np.mean(embeddings, axis=0)

        score = cosine_similarity(query_embedding, avg_embedding)

        if score > best_score:
            best_score = score
            best_label = label

    if best_score >= threshold:
        return {
            "label": best_label,
            "similarity": round(best_score, 4),
            "matched": True
        }

    return {
        "label": None,
        "similarity": round(best_score, 4),
        "matched": False
    }