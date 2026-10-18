#!/usr/bin/env python3
"""OrvixOS markalama PNG'lerini üretir (geliştirme aracı; Pillow ister).

Çıktılar branding/ dizinine yazılır ve depoya eklenir; ISO derlemesi
Pillow gerektirmez. Yazılar açık lisanslı Inter fontuyla (SIL OFL 1.1,
branding/fonts/) çizilir.
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "branding"
FONTS = OUT / "fonts"
BG = (11, 18, 32)
TEAL = (46, 230, 214)
VIOLET = (124, 92, 255)
MUTED = (155, 161, 182)
SUPERSAMPLE = 4

# 256 birimlik logo geometrisi (orvixos-logo.svg ile aynı): yörünge halkası
# ve sağ üstte bir uydu.
RING_CENTER = (124, 132)
RING_OUTER = 84
RING_INNER = 54
MOON_CENTER = (196, 62)
MOON_RADIUS = 22


def font(size, bold=True):
    return ImageFont.truetype(str(FONTS / ("Inter-Bold.ttf" if bold else "Inter-Medium.ttf")), size)


def gradient(size):
    width, height = size
    image = Image.new("RGB", size)
    pixels = image.load()
    for y in range(height):
        for x in range(width):
            t = (x / max(1, width - 1) + y / max(1, height - 1)) / 2
            pixels[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(TEAL, VIOLET))
    return image


def circle(draw, center, radius, scale, fill):
    cx, cy = center
    draw.ellipse(
        ((cx - radius) * scale, (cy - radius) * scale, (cx + radius) * scale, (cy + radius) * scale),
        fill=fill,
    )


def masks(size):
    big = size * SUPERSAMPLE
    scale = big / 256
    ring = Image.new("L", (big, big), 0)
    draw = ImageDraw.Draw(ring)
    circle(draw, RING_CENTER, RING_OUTER, scale, 255)
    circle(draw, RING_CENTER, RING_INNER, scale, 0)
    # Uydunun çevresinde halkada küçük bir boşluk bırakılır.
    circle(draw, MOON_CENTER, MOON_RADIUS + 10, scale, 0)
    moon = Image.new("L", (big, big), 0)
    circle(ImageDraw.Draw(moon), MOON_CENTER, MOON_RADIUS, scale, 255)
    return (ring.resize((size, size), Image.LANCZOS), moon.resize((size, size), Image.LANCZOS))


def draw_mark(canvas, x, y, size):
    size = int(size)
    ring, moon = masks(size)
    canvas.paste(gradient((size, size)), (int(x), int(y)), ring)
    canvas.paste(Image.new("RGB", (size, size), TEAL), (int(x), int(y)), moon)


def wordmark(draw, x, y, size):
    bold = font(size)
    draw.text((x, y), "Orvix", font=bold, fill=(255, 255, 255))
    width = draw.textlength("Orvix", font=bold)
    draw.text((x + width, y), "OS", font=bold, fill=TEAL)
    return width + draw.textlength("OS", font=bold)


def banner():
    image = Image.new("RGB", (800, 75), BG)
    draw = ImageDraw.Draw(image)
    draw_mark(image, 14, 4, 68)
    width = wordmark(draw, 92, 12, 36)
    draw.text((104 + width, 26), "Debian tabanlı • TRLDE masaüstü", font=font(17, bold=False), fill=MUTED)
    for name in ("installer-banner.png", "installer-banner-dark.png"):
        image.save(OUT / name, optimize=True)


def splash():
    image = Image.new("RGB", (640, 480), BG)
    draw = ImageDraw.Draw(image)
    draw_mark(image, 250, 50, 140)
    big = font(52)
    width = draw.textlength("OrvixOS", font=big)
    wordmark(draw, (640 - width) / 2, 200, 52)
    subtitle = "Debian tabanlı işletim sistemi"
    small = font(18, bold=False)
    draw.text(((640 - draw.textlength(subtitle, font=small)) / 2, 272), subtitle, font=small, fill=MUTED)
    image.save(OUT / "isolinux-splash.png", optimize=True)


def logo_png():
    size = 256
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    plate = Image.new("L", (size * SUPERSAMPLE, size * SUPERSAMPLE), 0)
    ImageDraw.Draw(plate).rounded_rectangle(
        (8 * SUPERSAMPLE, 8 * SUPERSAMPLE, 248 * SUPERSAMPLE, 248 * SUPERSAMPLE),
        radius=56 * SUPERSAMPLE,
        fill=255,
    )
    plate = plate.resize((size, size), Image.LANCZOS)
    image.paste(Image.new("RGBA", (size, size), BG + (255,)), (0, 0), plate)
    ring, moon = masks(size)
    image.paste(gradient((size, size)), (0, 0), ring)
    image.paste(Image.new("RGB", (size, size), TEAL), (0, 0), moon)
    image.save(OUT / "orvixos-logo-256.png", optimize=True)


def login_wordmark():
    """GDM giriş ekranı için şeffaf, yatay logo (Debian'ınki gibi ~64 px)."""
    height = 64
    probe = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    bold = font(40)
    text_width = probe.textlength("OrvixOS", font=bold)
    width = int(height + 16 + text_width + 4)
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    ring, moon = masks(height)
    image.paste(gradient((height, height)), (0, 0), ring)
    image.paste(Image.new("RGB", (height, height), TEAL), (0, 0), moon)
    draw = ImageDraw.Draw(image)
    draw.text((height + 16, 6), "Orvix", font=bold, fill=(255, 255, 255, 255))
    draw.text((height + 16 + probe.textlength("Orvix", font=bold), 6), "OS", font=bold, fill=TEAL + (255,))
    image.save(OUT / "orvixos-login.png", optimize=True)


def live_boot_splash():
    """Canlı ISO GRUB menüsü arka planı (800x600; menü alt yarıda)."""
    image = Image.new("RGB", (800, 600), BG)
    draw = ImageDraw.Draw(image)
    draw_mark(image, 340, 70, 120)
    big = font(48)
    width = draw.textlength("OrvixOS", font=big)
    wordmark(draw, (800 - width) / 2, 200, 48)
    image.save(OUT / "live-boot-splash.png", optimize=True)


if __name__ == "__main__":
    live_boot_splash()
    login_wordmark()
    banner()
    splash()
    logo_png()
    print("Markalama görüntüleri üretildi:", OUT)
