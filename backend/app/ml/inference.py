import hashlib
import json
import unicodedata
from pathlib import Path

import joblib


class Model:
    def __init__(self, path):
        self.pipeline = None
        self.version = None
        if path:
            import sklearn

            artifact = Path(path)
            manifest = json.loads(artifact.with_suffix(".json").read_text())
            if manifest.get("schema_version") != 1:
                raise ValueError("Unsupported model schema")
            if manifest.get("normalization") != "NFKC-whitespace-v1":
                raise ValueError("Unsupported model normalization")
            if manifest.get("sklearn_version") != sklearn.__version__:
                raise ValueError("Model sklearn version mismatch")
            if hashlib.sha256(artifact.read_bytes()).hexdigest() != manifest["sha256"]:
                raise ValueError("Model checksum mismatch")
            # Only load administrator-provisioned artifacts. joblib is executable serialization.
            self.pipeline = joblib.load(artifact)
            self.version = manifest["model_version"]

    def predict(self, text):
        if self.pipeline is None:
            return None
        text = " ".join(unicodedata.normalize("NFKC", text).split())
        classes = list(self.pipeline.classes_)
        value = float(self.pipeline.predict_proba([text])[0][classes.index(1)])
        if not 0 <= value <= 1:
            raise ValueError("Invalid model output")
        return value
