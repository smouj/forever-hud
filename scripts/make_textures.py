"""Generates the HUD textures shipped in ForeverHUD/Media.

Run from the repository root: python3 scripts/make_textures.py
All textures are 32-bit TGA, power-of-two sizes, no external dependencies
beyond Pillow.
"""
from PIL import Image

def smooth_bar(path, width=64, height=32):
    img = Image.new("RGB", (width, height), (255, 255, 255))
    px = img.load()
    for y in range(height):
        t = y / (height - 1)
        # bright top edge, gentle falloff, slight lift at the bottom
        if t < 0.12:
            v = 255
        elif t < 0.5:
            v = int(255 - (t - 0.12) * 70)
        else:
            v = int(228 - (t - 0.5) * 60)
        for x in range(width):
            # subtle vertical banding to avoid a flat plastic look
            band = 4 if (x // 8) % 2 == 0 else 0
            value = max(0, min(255, v + band))
            px[x, y] = (value, value, value)
    img.save(path, format="TGA")
    print("wrote", path, img.size)

def flat_bar(path, size=8):
    Image.new("RGB", (size, size), (255, 255, 255)).save(path, format="TGA")
    print("wrote", path, (size, size))

def spark(path, size=32):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    cx = cy = (size - 1) / 2.0
    for y in range(size):
        for x in range(size):
            dx = (x - cx) / cx
            dy = (y - cy) / cy
            dist = (dx * dx + dy * dy) ** 0.5
            alpha = max(0.0, 1.0 - dist)
            alpha = alpha ** 2.2
            px[x, y] = (255, 255, 255, int(alpha * 255))
    img.save(path, format="TGA")
    print("wrote", path, (size, size))

if __name__ == "__main__":
    smooth_bar("ForeverHUD/Media/bar-smooth.tga")
    flat_bar("ForeverHUD/Media/bar-flat.tga")
    spark("ForeverHUD/Media/spark.tga")
