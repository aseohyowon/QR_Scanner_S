"""
QR Scanner & Generator — App Icon Generator
Produces ic_launcher.png for every Android mipmap density.

Design:
  - Dark navy background (#0D1117)
  - Rounded-square shape (squircle-ish via large corner radius)
  - Centre QR code pattern (simplified, recognisable, bright cyan #00E5FF)
  - Scan-frame corner brackets in vivid blue-green (#29FFA3)
  - Subtle radial glow behind QR for depth
"""

import math
import os
from PIL import Image, ImageDraw

# ── Android mipmap density targets ──────────────────────────────────────────
DENSITIES = {
    "mipmap-mdpi":    48,
    "mipmap-hdpi":    72,
    "mipmap-xhdpi":   96,
    "mipmap-xxhdpi":  144,
    "mipmap-xxxhdpi": 192,
}

BASE_DIR = os.path.join(
    os.path.dirname(__file__),
    "..", "android", "app", "src", "main", "res"
)

# ── Colour palette ───────────────────────────────────────────────────────────
BG          = (13,  17,  23,  255)   # #0D1117  dark navy
QR_COLOR    = (0,   229, 255, 255)   # #00E5FF  cyan
FRAME_COLOR = (41,  255, 163, 255)   # #29FFA3  bright mint-green
GLOW_COLOR  = (0,   180, 220,  60)   # soft cyan glow (transparent)


# ── Helpers ──────────────────────────────────────────────────────────────────

def lerp(a, b, t):
    return a + (b - a) * t


def draw_rounded_rect(draw, xy, radius, fill):
    """Draw a filled rounded rectangle."""
    x0, y0, x1, y1 = xy
    # Clamp radius so corners never overlap
    max_r = max(0, min(radius, (x1 - x0) / 2, (y1 - y0) / 2))
    r = max_r
    if x1 - x0 <= 0 or y1 - y0 <= 0:
        return
    # Fill body
    if x0 + r <= x1 - r:
        draw.rectangle([x0 + r, y0, x1 - r, y1], fill=fill)
    if y0 + r <= y1 - r:
        draw.rectangle([x0, y0 + r, x1, y1 - r], fill=fill)
    # Corners
    d = r * 2
    if d > 0:
        draw.ellipse([x0, y0, x0 + d, y0 + d], fill=fill)
        draw.ellipse([x1 - d, y0, x1, y0 + d], fill=fill)
        draw.ellipse([x0, y1 - d, x0 + d, y1], fill=fill)
        draw.ellipse([x1 - d, y1 - d, x1, y1], fill=fill)


def radial_glow(img, cx, cy, radius, color):
    """Paint a soft radial glow using concentric circles with diminishing alpha."""
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    steps = 24
    r, g, b, a = color
    for i in range(steps, 0, -1):
        t = i / steps
        cr = int(radius * t)
        alpha = int(a * (1 - t) * 0.9)
        draw.ellipse(
            [cx - cr, cy - cr, cx + cr, cy + cr],
            fill=(r, g, b, alpha)
        )
    img = Image.alpha_composite(img, overlay)
    return img


# ── QR cell matrix (13×13 logical units) ──────────────────────────────────
# 1 = filled module, 0 = empty.  This represents a stylised, recognisable
# QR-like pattern with 3 finder patterns and internal data modules.
QR_MATRIX = [
    [1,1,1,1,1,1,1, 0, 1,1,1,1,1],
    [1,0,0,0,0,0,1, 0, 1,0,0,0,1],
    [1,0,1,1,1,0,1, 0, 1,0,1,0,1],
    [1,0,1,1,1,0,1, 0, 1,0,1,0,1],
    [1,0,1,1,1,0,1, 0, 1,0,0,0,1],
    [1,0,0,0,0,0,1, 0, 0,0,1,0,0],
    [1,1,1,1,1,1,1, 0, 1,0,1,0,1],
    [0,0,0,0,0,0,0, 0, 0,1,0,0,0],
    [1,1,1,1,1,1,1, 1, 0,1,0,1,1],
    [1,0,0,0,0,0,1, 0, 1,0,0,0,1],
    [1,0,1,1,1,0,1, 1, 0,1,0,1,0],
    [1,0,0,0,0,0,1, 0, 1,0,1,0,1],
    [1,1,1,1,1,1,1, 0, 0,1,0,1,1],
]

MATRIX_SIZE = 13  # cells


def draw_qr(draw, ox, oy, total_size, color):
    """Render QR matrix centred at (ox, oy) spanning total_size px."""
    cell = total_size / MATRIX_SIZE
    r = max(1, cell * 0.08)  # tiny corner rounding proportional to cell
    for row in range(MATRIX_SIZE):
        for col in range(MATRIX_SIZE):
            if QR_MATRIX[row][col]:
                x0 = ox + col * cell
                y0 = oy + row * cell
                x1 = x0 + cell
                y1 = y0 + cell
                # small inset for module gap
                gap = cell * 0.07
                draw_rounded_rect(
                    draw,
                    (x0 + gap, y0 + gap, x1 - gap, y1 - gap),
                    radius=r,
                    fill=color,
                )


def draw_scan_frame(draw, size, color, thickness, arm_len_frac=0.22):
    """Draw 4-corner scan-frame brackets inside the icon."""
    margin = size * 0.06
    arm = size * arm_len_frac
    t = thickness
    corners = [
        # (x_start, y_start, dx_horiz, dy_vert)
        (margin,        margin,        1,  1),
        (size - margin, margin,       -1,  1),
        (margin,        size - margin,  1, -1),
        (size - margin, size - margin, -1, -1),
    ]
    for cx, cy, dx, dy in corners:
        # horizontal arm
        x0 = cx if dx > 0 else cx - arm
        x1 = cx + arm if dx > 0 else cx
        draw.rectangle([x0, cy, x1, cy + t * dy if dy > 0 else cy + t], fill=color)
        # vertical arm
        y0 = cy if dy > 0 else cy - arm
        y1 = cy + arm if dy > 0 else cy
        draw.rectangle([cx, y0, cx + t * dx if dx > 0 else cx + t, y1], fill=color)


# ── Main generation ──────────────────────────────────────────────────────────

def generate_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Background rounded square
    radius = size * 0.22
    draw_rounded_rect(draw, (0, 0, size, size), radius=radius, fill=BG)

    # 2. Radial glow behind QR
    glow_r = size * 0.42
    img = radial_glow(img, size // 2, size // 2, glow_r, GLOW_COLOR)
    draw = ImageDraw.Draw(img)

    # 3. QR pattern
    qr_size = size * 0.56
    qr_ox = (size - qr_size) / 2
    qr_oy = (size - qr_size) / 2
    draw_qr(draw, qr_ox, qr_oy, qr_size, QR_COLOR)

    # 4. Scan frame brackets (on top)
    frame_thickness = max(2, size * 0.045)
    draw_scan_frame(draw, size, FRAME_COLOR, frame_thickness, arm_len_frac=0.20)

    return img


def main():
    for density, size in DENSITIES.items():
        out_dir = os.path.join(BASE_DIR, density)
        os.makedirs(out_dir, exist_ok=True)
        icon = generate_icon(size)
        # Convert to RGB for PNG (remove alpha so Android mipmap renders correctly)
        bg = Image.new("RGB", icon.size, (13, 17, 23))
        bg.paste(icon, mask=icon.split()[3])
        out_path = os.path.join(out_dir, "ic_launcher.png")
        bg.save(out_path, "PNG", optimize=True)
        print(f"  ✓ {density:20s} {size}×{size}px  →  {out_path}")

    print("\nDone! All ic_launcher.png files generated.")


if __name__ == "__main__":
    main()
