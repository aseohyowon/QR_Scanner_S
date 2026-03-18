"""
Generate splash_icon.png — transparent background, QR + scan-frame design.
512x512, suitable for flutter_native_splash input.
"""
import os
from PIL import Image, ImageDraw

SIZE = 512
out_dir = r"assets"
os.makedirs(out_dir, exist_ok=True)

img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

CYAN = (0, 229, 255, 255)
MINT = (41, 255, 163, 255)

MATRIX = [
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
CELLS = 13


def draw_rounded_rect(draw, xy, radius, fill):
    x0, y0, x1, y1 = xy
    r = max(0, min(radius, (x1 - x0) / 2, (y1 - y0) / 2))
    if x1 - x0 <= 0 or y1 - y0 <= 0:
        return
    if x0 + r <= x1 - r:
        draw.rectangle([x0 + r, y0, x1 - r, y1], fill=fill)
    if y0 + r <= y1 - r:
        draw.rectangle([x0, y0 + r, x1, y1 - r], fill=fill)
    d = r * 2
    if d > 0:
        draw.ellipse([x0, y0, x0 + d, y0 + d], fill=fill)
        draw.ellipse([x1 - d, y0, x1, y0 + d], fill=fill)
        draw.ellipse([x0, y1 - d, x0 + d, y1], fill=fill)
        draw.ellipse([x1 - d, y1 - d, x1, y1], fill=fill)


# QR matrix
qr_area = SIZE * 0.60
ox = (SIZE - qr_area) / 2
oy = (SIZE - qr_area) / 2
cell = qr_area / CELLS
gap = cell * 0.09
r = cell * 0.14

for row in range(CELLS):
    for col in range(CELLS):
        if MATRIX[row][col]:
            draw_rounded_rect(
                draw,
                (ox + col * cell + gap, oy + row * cell + gap,
                 ox + col * cell + cell - gap, oy + row * cell + cell - gap),
                r, CYAN,
            )

# Scan frame brackets
margin = SIZE * 0.06
arm = SIZE * 0.20
t = SIZE * 0.04
corners = [(margin, margin), (SIZE - margin, margin),
           (margin, SIZE - margin), (SIZE - margin, SIZE - margin)]
dirs = [(1, 1), (-1, 1), (1, -1), (-1, -1)]
for (cx, cy), (dx, dy) in zip(corners, dirs):
    hx0 = cx if dx > 0 else cx - arm
    hy0 = cy if dy > 0 else cy - t
    draw.rectangle([hx0, hy0, hx0 + arm, hy0 + t], fill=MINT)
    vx0 = cx if dx > 0 else cx - t
    vy0 = cy if dy > 0 else cy - arm
    draw.rectangle([vx0, vy0, vx0 + t, vy0 + arm], fill=MINT)

out = os.path.join(out_dir, "splash_icon.png")
img.save(out, "PNG")
print(f"Saved: {out}  ({SIZE}x{SIZE} RGBA)")
