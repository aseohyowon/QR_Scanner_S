from PIL import Image, ImageDraw, ImageFont

# 1024x500 그래픽 이미지 생성
img = Image.new("RGB", (1024, 500), (13, 17, 23))  # 다크 네이비 배경

draw = ImageDraw.Draw(img)

# 중앙에 밝은 사각형 (로고 느낌)
draw.rounded_rectangle([312, 100, 712, 400], radius=60, fill=(0,229,255))

# 텍스트 (폰트는 기본)
draw.text((370, 220), "QR Scanner\n& Generator", fill=(255,255,255))

img.save("assets/graphic_1024x500.png")
print("Saved: assets/graphic_1024x500.png")
