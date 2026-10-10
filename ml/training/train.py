"""Reproducible text baseline. Run on a licensed CSV with text,label columns."""

import argparse
import csv
import hashlib
import json
import re
import unicodedata
from pathlib import Path

import joblib
import sklearn
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    average_precision_score,
    classification_report,
    confusion_matrix,
    precision_recall_fscore_support,
)
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline


def train(dataset, output, provenance, version="text-baseline-1"):
    info = json.loads(Path(provenance).read_text(encoding="utf-8"))
    if not all(info.get(k) for k in ["source", "license", "label_definition"]):
        raise ValueError("Provenance requires source, license and label_definition")
    rows = {}
    conflicts = set()
    with Path(dataset).open(encoding="utf-8", newline="") as stream:
        for row in csv.DictReader(stream):
            text = " ".join(unicodedata.normalize("NFKC", row["text"]).split())
            label = int(row["label"])
            if not text or label not in {0, 1}:
                raise ValueError("Expected nonempty text and label 0 or 1")
            # Collapse variable numbers/URLs to reduce template leakage across splits.
            key = re.sub(r"https?://\S+|\d+", "<variable>", text.lower())
            if key in rows and rows[key][1] != label:
                conflicts.add(key)
            rows[key] = (text, label)
    for key in conflicts:
        rows.pop(key, None)
    texts, labels = zip(*rows.values(), strict=True)
    if min(labels.count(0), labels.count(1)) < 20:
        raise ValueError("At least 20 unique samples per class required")
    x_train, x_remaining, y_train, y_remaining = train_test_split(
        texts, labels, test_size=0.3, stratify=labels, random_state=42
    )
    x_validation, x_test, y_validation, y_test = train_test_split(
        x_remaining, y_remaining, test_size=0.5, stratify=y_remaining, random_state=42
    )
    model = Pipeline(
        [
            (
                "tfidf",
                TfidfVectorizer(
                    ngram_range=(1, 2), min_df=2, max_features=30000, sublinear_tf=True
                ),
            ),
            (
                "classifier",
                LogisticRegression(
                    max_iter=1000, class_weight="balanced", random_state=42
                ),
            ),
        ]
    )
    model.fit(x_train, y_train)
    validation_predictions = model.predict(x_validation)
    predictions = model.predict(x_test)
    signal = model.predict_proba(x_test)[:, list(model.classes_).index(1)]
    p, r, f1, _ = precision_recall_fscore_support(y_test, predictions, average="binary")
    report = {
        "dataset": info,
        "dataset_sha256": hashlib.sha256(Path(dataset).read_bytes()).hexdigest(),
        "seed": 42,
        "unique_examples": len(rows),
        "conflicting_templates_removed": len(conflicts),
        "split": {
            "train": len(x_train),
            "validation": len(x_validation),
            "test": len(x_test),
        },
        "validation": classification_report(
            y_validation, validation_predictions, output_dict=True
        ),
        "test": {
            "precision": float(p),
            "recall": float(r),
            "f1": float(f1),
            "pr_auc": float(average_precision_score(y_test, signal)),
            "confusion_matrix": confusion_matrix(y_test, predictions).tolist(),
        },
        "limitations": [
            "Spam labels are not verified fraud labels unless provenance says otherwise.",
            "Template normalization reduces but cannot eliminate semantic leakage.",
            "Not validated for URL, email, voice, regional languages or deployment traffic.",
            "Model outputs are uncalibrated signals.",
        ],
    }
    artifact = Path(output)
    artifact.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(model, artifact)
    manifest = {
        "schema_version": 1,
        "normalization": "NFKC-whitespace-v1",
        "model_version": version,
        "sklearn_version": sklearn.__version__,
        "sha256": hashlib.sha256(artifact.read_bytes()).hexdigest(),
        "training_report": report,
    }
    artifact.with_suffix(".json").write_text(
        json.dumps(manifest, indent=2), encoding="utf-8"
    )
    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset", required=True)
    parser.add_argument("--provenance", required=True)
    parser.add_argument("--output", default="ml/artifacts/baseline.joblib")
    args = parser.parse_args()
    print(json.dumps(train(args.dataset, args.output, args.provenance), indent=2))
