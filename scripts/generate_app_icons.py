#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]

BACKGROUND = (21, 47, 56)
BOOKMARK = (244, 205, 120)


def draw_mark(image, scale=1.0):
    mask = Image.new("L", image.size, 0)
    draw = ImageDraw.Draw(mask)

    draw.rounded_rectangle(
        [330 * scale, 184 * scale, 694 * scale, 846 * scale],
        radius=92 * scale,
        fill=255,
    )
    draw.polygon(
        [
            (394 * scale, 846 * scale),
            (512 * scale, 724 * scale),
            (630 * scale, 846 * scale),
        ],
        fill=0,
    )
    image.paste(Image.new("RGBA", image.size, BOOKMARK + (255,)), (0, 0), mask)


def full_icon(size):
    image = Image.new("RGBA", (size, size), BACKGROUND + (255,))
    draw_mark(image, scale=size / 1024)
    return image.convert("RGB")


def adaptive_foreground(size):
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_mark(image, scale=size / 1024)
    return image


def save_icon(path, image):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, "PNG", optimize=True)


def generate_ios():
    base = full_icon(1024)
    icons = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    target = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for filename, size in icons.items():
        save_icon(target / filename, base.resize((size, size), Image.Resampling.LANCZOS))


def generate_android():
    base = full_icon(1024)
    legacy = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    res = ROOT / "android/app/src/main/res"
    for folder, size in legacy.items():
        save_icon(
            res / folder / "ic_launcher.png",
            base.resize((size, size), Image.Resampling.LANCZOS),
        )

    foreground_sizes = {
        "mipmap-mdpi": 108,
        "mipmap-hdpi": 162,
        "mipmap-xhdpi": 216,
        "mipmap-xxhdpi": 324,
        "mipmap-xxxhdpi": 432,
    }
    foreground = adaptive_foreground(1024)
    for folder, size in foreground_sizes.items():
        save_icon(
            res / folder / "ic_launcher_foreground.png",
            foreground.resize((size, size), Image.Resampling.LANCZOS),
        )


def main():
    generate_ios()
    generate_android()


if __name__ == "__main__":
    main()
