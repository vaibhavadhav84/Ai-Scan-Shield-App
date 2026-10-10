"""Explicit fixed-source download. Data stays gitignored and is never application seed data."""

import csv
import io
import json
import urllib.request
import zipfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
folder = root / "ml/data"
folder.mkdir(parents=True, exist_ok=True)
url = "https://archive.ics.uci.edu/static/public/228/sms+spam+collection.zip"
with urllib.request.urlopen(url, timeout=30) as response:
    raw = response.read(5 * 1024 * 1024 + 1)
if len(raw) > 5 * 1024 * 1024:
    raise ValueError("Dataset exceeds download limit")
with zipfile.ZipFile(io.BytesIO(raw)) as archive:
    # Read a known member, never extract untrusted archive paths.
    content = archive.read("SMSSpamCollection").decode("utf-8")
with (folder / "uci_sms.csv").open("w", encoding="utf-8", newline="") as stream:
    writer = csv.writer(stream)
    writer.writerow(["text", "label"])
    for line in content.splitlines():
        label, text = line.split("\t", 1)
        if label not in {"ham", "spam"}:
            raise ValueError("Unexpected label")
        writer.writerow([text, int(label == "spam")])
(folder / "uci_provenance.json").write_text(
    json.dumps(
        {
            "source": "https://archive.ics.uci.edu/dataset/228/sms+spam+collection",
            "license": "CC BY 4.0 as stated by UCI dataset page; attribution required",
            "label_definition": "0=ham, 1=spam. Spam is a proxy, not a verified fraud label.",
            "purpose": "Offline baseline evaluation only. Not enabled for production inference by default.",
        },
        indent=2,
    ),
    encoding="utf-8",
)
print(
    "Downloaded licensed SMS spam corpus for offline evaluation; not enabled in application."
)
