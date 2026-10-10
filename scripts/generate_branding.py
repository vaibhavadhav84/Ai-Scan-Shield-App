"""Render original geometry into SVG masters and platform icon assets."""

import json
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
folder = root / "assets/branding"
folder.mkdir(parents=True, exist_ok=True)
shield = [(50, 8), (86, 22), (84, 57), (70, 80), (50, 94), (30, 80), (16, 57), (14, 22)]
body = """<path d="M50 8 L86 22 L84 57 L70 80 L50 94 L30 80 L16 57 L14 22 Z" fill="#2478f5"/>
<path d="M50 21 L73 30 L71 53 L61 70 L50 79 L39 70 L29 53 L27 30 Z" fill="#102039"/>
<path d="M34 52 L45 63 L66 40" fill="none" stroke="#38d4b2" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>
<circle cx="34" cy="52" r="4" fill="#e8f5ff"/><circle cx="66" cy="40" r="4" fill="#e8f5ff"/>"""
for name, bg in [
    ("icon", None),
    ("logo-dark", "#0b1526"),
    ("logo-light", "#ffffff"),
    ("monochrome", None),
]:
    geometry = body
    if name == "monochrome":
        geometry = body.replace("#2478f5", "#102039").replace("#38d4b2", "#ffffff")
    background = f'<rect width="100" height="100" rx="20" fill="{bg}"/>' if bg else ""
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" role="img"><title>Scan Shield</title>{background}{geometry}</svg>'
    ET.fromstring(svg)
    (folder / f"{name}.svg").write_text(svg, encoding="utf-8")
    mobile = root / "mobile/assets/branding"
    mobile.mkdir(parents=True, exist_ok=True)
    (mobile / f"{name}.svg").write_text(svg, encoding="utf-8")


def icon(size):
    # Supersampling makes small launcher icons legible. Same points as the SVG.
    side = size * 4
    img = Image.new("RGB", (side, side), "#0b1526")
    draw = ImageDraw.Draw(img)
    scale = side / 100
    coords = lambda points: [(round(x * scale), round(y * scale)) for x, y in points]
    draw.polygon(coords(shield), fill="#2478f5")
    draw.polygon(
        coords(
            [
                (50, 21),
                (73, 30),
                (71, 53),
                (61, 70),
                (50, 79),
                (39, 70),
                (29, 53),
                (27, 30),
            ]
        ),
        fill="#102039",
    )
    draw.line(
        coords([(34, 52), (45, 63), (66, 40)]), fill="#38d4b2", width=round(7 * scale)
    )
    for x, y in [(34, 52), (66, 40)]:
        draw.ellipse(
            [
                (int((x - 4) * scale), int((y - 4) * scale)),
                (int((x + 4) * scale), int((y + 4) * scale)),
            ],
            fill="#e8f5ff",
        )
    return img.resize((size, size), Image.Resampling.LANCZOS)


icon(1024).save(folder / "app-icon-1024.png")
for density, size in [
    ("mdpi", 48),
    ("hdpi", 72),
    ("xhdpi", 96),
    ("xxhdpi", 144),
    ("xxxhdpi", 192),
]:
    target = root / f"mobile/android/app/src/main/res/mipmap-{density}/ic_launcher.png"
    icon(size).save(target)
for density, size in [
    ("mdpi", 96),
    ("hdpi", 144),
    ("xhdpi", 192),
    ("xxhdpi", 288),
    ("xxxhdpi", 384),
]:
    target = (
        root / f"mobile/android/app/src/main/res/drawable-{density}/splash_icon.png"
    )
    target.parent.mkdir(parents=True, exist_ok=True)
    icon(size).save(target)
ios = root / "mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset"
for entry in json.loads((ios / "Contents.json").read_text())["images"]:
    side = round(float(entry["size"].split("x")[0]) * float(entry["scale"].rstrip("x")))
    if "filename" in entry:
        icon(side).save(ios / entry["filename"])
launch = root / "mobile/ios/Runner/Assets.xcassets/LaunchImage.imageset"
for entry in json.loads((launch / "Contents.json").read_text())["images"]:
    if "filename" in entry:
        icon(round(96 * float(entry["scale"].rstrip("x")))).save(
            launch / entry["filename"]
        )
icon(32).save(folder / "favicon.png")
(folder / "BRAND_GUIDE.md").write_text(
    """# Scan Shield brand
Original shield geometry with linked detection nodes and a check motif. Product name:
AI-Powered Multi-Channel Fraud Detection System; short UI name Scan Shield.
Navy #0b1526, blue #2478f5, teal #38d4b2. Risk colors: safe #087d69,
suspicious #966000, high risk #c43b48; always pair color with text and icon.
System sans-serif, 16px body, 24-32px headings. Use an 8px spacing grid and 48px touch targets.
Logo clear space: 12% of width; minimum icon width 24px. Use dark/light variants on matching
backgrounds and monochrome for one-color output. Never stretch or add institutional marks.
SVG masters are editable; generated PNGs are opaque for iOS compatibility.
""",
    encoding="utf-8",
)
print("Validated SVG masters and generated Android/iOS icons and splash assets.")
