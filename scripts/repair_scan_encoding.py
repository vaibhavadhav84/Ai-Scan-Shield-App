from pathlib import Path

path = Path(__file__).resolve().parents[1] / "mobile/lib/features/scan/scan_screen.dart"
raw = path.read_bytes()
text = raw.decode("utf-8", errors="surrogateescape")
bad = [c for c in text if 0xDC80 <= ord(c) <= 0xDCFF]
text = "".join(
    bytes([ord(c) - 0xDC00]).decode("cp1252") if 0xDC80 <= ord(c) <= 0xDCFF else c
    for c in text
)
path.write_text(text, encoding="utf-8")
print(f"Normalized {len(bad)} legacy encoded source bytes to UTF-8.")
