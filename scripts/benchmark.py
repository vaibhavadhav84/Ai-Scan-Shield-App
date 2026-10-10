"""Small local rules benchmark, never a production load-test claim."""

import json
import statistics
import time
from pathlib import Path

from app.schemas import ScanInput
from app.services.detection import detect

request = ScanInput(
    channel="sms",
    content="Send your OTP immediately or your bank account will be blocked.",
)
samples = []
for _ in range(200):
    start = time.perf_counter()
    detect(request)
    samples.append((time.perf_counter() - start) * 1000)
report = {
    "samples": 200,
    "median_ms": statistics.median(samples),
    "p95_ms": sorted(samples)[189],
    "scope": "local rules inference only, no HTTP/database/providers",
}
Path("docs/benchmark.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print(json.dumps(report))
