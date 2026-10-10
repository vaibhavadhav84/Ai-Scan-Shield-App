import io
import tempfile
import wave
from pathlib import Path

import httpx
from fastapi import HTTPException

from app.core.config import settings


def reputation(url):
    cfg = settings()
    if cfg.reputation_provider == "disabled" or not cfg.reputation_api_key:
        return {"status": "unconfigured", "listed": None}
    try:
        # Fixed HTTPS provider endpoint; never fetch the submitted destination.
        response = httpx.post(
            "https://safebrowsing.googleapis.com/v4/threatMatches:find",
            params={"key": cfg.reputation_api_key},
            timeout=5,
            json={
                "client": {"clientId": "scan-shield", "clientVersion": "0.1"},
                "threatInfo": {
                    "threatTypes": ["MALWARE", "SOCIAL_ENGINEERING"],
                    "platformTypes": ["ANY_PLATFORM"],
                    "threatEntryTypes": ["URL"],
                    "threatEntries": [{"url": url}],
                },
            },
        )
        response.raise_for_status()
        data = response.json()
        return {"status": "available", "listed": bool(data.get("matches"))}
    except (httpx.HTTPError, ValueError):
        return {"status": "unavailable", "listed": None}


def validate_audio(data):
    cfg = settings()
    if not data or len(data) > cfg.max_audio_bytes:
        raise HTTPException(413, "WAV must be non-empty and at most 10 MB")
    try:
        with wave.open(io.BytesIO(data)) as recording:
            duration = recording.getnframes() / recording.getframerate()
            if (
                recording.getnchannels() not in {1, 2}
                or recording.getsampwidth() not in {1, 2, 3, 4}
                or not 8000 <= recording.getframerate() <= 48000
                or not 0 < duration <= cfg.max_audio_seconds
            ):
                raise ValueError("Unsupported WAV parameters")
            expected = recording.getnframes() * recording.getnchannels() * recording.getsampwidth()
            if len(recording.readframes(recording.getnframes())) != expected:
                raise ValueError("Truncated audio")
        return duration
    except (wave.Error, EOFError, ValueError, ZeroDivisionError) as exc:
        raise HTTPException(422, "Valid PCM WAV, 8-48 kHz, max 180 seconds required") from exc


def transcribe(data):
    validate_audio(data)
    cfg = settings()
    if not cfg.speech_model_path:
        raise HTTPException(
            503, "Speech recognition is not configured. Submit a transcript instead."
        )
    if not Path(cfg.speech_model_path).is_dir():
        raise HTTPException(503, "Local speech model unavailable")
    try:
        from faster_whisper import WhisperModel

        # TemporaryDirectory deletes uploaded audio on success and failure.
        with tempfile.TemporaryDirectory(prefix="scan-shield-") as folder:
            path = Path(folder) / "audio.wav"
            path.write_bytes(data)
            model = WhisperModel(
                cfg.speech_model_path,
                device="cpu",
                compute_type="int8",
                local_files_only=True,
                cpu_threads=2,
            )
            segments, _ = model.transcribe(str(path), beam_size=1, language="en")
            transcript = " ".join(segment.text.strip() for segment in segments)
            if not transcript.strip() or len(transcript) > 20000:
                raise HTTPException(422, "No usable speech transcript")
            return transcript
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(503, "Speech recognition unavailable; retry or submit text") from exc
