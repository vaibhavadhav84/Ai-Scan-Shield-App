import json
import sys
from pathlib import Path

import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, inspect

from app.ml.inference import Model


def test_migration_upgrade_downgrade(tmp_path, monkeypatch):
    from app.core.config import settings

    database = tmp_path / "migration.db"
    monkeypatch.setattr(settings(), "database_url", f"sqlite:///{database.as_posix()}")
    config = Config("alembic.ini")
    command.upgrade(config, "head")
    engine = create_engine(settings().database_url)
    assert {"users", "scans", "reports", "sessions", "rate_buckets"} <= set(
        inspect(engine).get_table_names()
    )
    command.downgrade(config, "base")
    assert "users" not in inspect(engine).get_table_names()
    engine.dispose()


def test_missing_model_is_explicit():
    assert Model("").predict("text") is None
    with pytest.raises(FileNotFoundError):
        Model("missing-model.joblib")


def test_reproducible_training_loading_and_hash(tmp_path):
    root = Path(__file__).resolve().parents[2]
    sys.path.insert(0, str(root / "ml/training"))
    import csv

    from train import train

    dataset = tmp_path / "synthetic.csv"
    with dataset.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream)
        writer.writerow(["text", "label"])
        for i in range(60):
            suffix = chr(65 + i // 26) + chr(65 + i % 26)
            writer.writerow([f"Meeting schedule for project {suffix}", 0])
            writer.writerow([f"Share your password urgently reward {suffix}", 1])
    provenance = tmp_path / "source.json"
    provenance.write_text(
        json.dumps(
            {
                "source": "original synthetic fixtures",
                "license": "CC0",
                "label_definition": "functional test labels only",
            }
        )
    )
    artifact = tmp_path / "test.joblib"
    report = train(dataset, artifact, provenance)
    assert report["split"]["test"] > 0
    assert 0 <= report["test"]["f1"] <= 1
    assert 0 <= Model(str(artifact)).predict("Share your password") <= 1
    artifact.write_bytes(artifact.read_bytes() + b"tampered")
    with pytest.raises(ValueError, match="checksum"):
        Model(str(artifact))
