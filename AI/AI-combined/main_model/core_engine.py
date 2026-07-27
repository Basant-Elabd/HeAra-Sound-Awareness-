# =========================
# Core Decision Engine
# =========================

CLASS_CONFIG = {
    "gunshot": {"priority": "critical", "threshold": 0.50},
    "siren": {"priority": "critical", "threshold": 0.50},
    "cracking": {"priority": "critical", "threshold": 0.55},

    "crying": {"priority": "high", "threshold": 0.60},

    "door_bell": {"priority": "normal", "threshold": 0.75},
    "train": {"priority": "normal", "threshold": 0.75},

    "car": {"priority": "low", "threshold": 0.80},
    "dog": {"priority": "low", "threshold": 0.80},
    "cat": {"priority": "low", "threshold": 0.80},
    "rain": {"priority": "low", "threshold": 0.85},
}

NOISE_CLASS = "silence"


def get_config(label: str):
    return CLASS_CONFIG.get(label.lower(), {"priority": "low", "threshold": 0.80})


def should_alert(label, confidence, smoothed_label=None):

    if label is None:
        return False, None

    if label.lower() == NOISE_CLASS:
        return False, None

    config = get_config(label)
    priority = config["priority"]
    threshold = config["threshold"]

    # 🚨 Critical
    if priority == "critical" and confidence >= threshold:
        return True, label

    # ⚠️ High
    if priority == "high" and confidence >= threshold:
        return True, label

    # 🔔 Normal
    if priority == "normal":
        if confidence >= threshold:
            return True, label
        if smoothed_label:
            return True, smoothed_label

    # 🌙 Low
    if priority == "low" and smoothed_label:
        return True, smoothed_label

    return False, None