from PIL import Image, ImageDraw

S = 4
W = 512
size = W * S

def pts(points):
    return [(x * S, y * S) for x, y in points]

shield = [(256, 26), (432, 88), (432, 268), (256, 478), (80, 268), (80, 88)]
inner = [(256, 60), (406, 110), (406, 258), (256, 438), (106, 258), (106, 110)]

base = Image.new("RGBA", (size, size), (0, 0, 0, 0))

# gradient clipped to the shield silhouette
mask = Image.new("L", (size, size), 0)
ImageDraw.Draw(mask).polygon(pts(shield), fill=255)

gradient = Image.new("RGBA", (size, size), (0, 0, 0, 255))
g = ImageDraw.Draw(gradient)
for y in range(0, size, 2):
    t = y / size
    shade = int(24 - 14 * t)
    g.line([(0, y), (size, y)], fill=(shade, shade + 2, shade + 7, 255), width=2)
gradient.putalpha(255)
base.paste(gradient, (0, 0), mask)

d = ImageDraw.Draw(base)
d.polygon(pts(inner), fill=(15, 17, 23, 255))

# gold outline
d.line(pts(shield + [shield[0]]), fill=(217, 173, 82, 255), width=10 * S, joint="curve")
d.line(pts(inner), fill=(74, 61, 41, 255), width=3 * S, joint="curve")

# rune
gold = (231, 196, 126, 255)
gold_dim = (168, 130, 70, 255)
d.line([(256 * S, 128 * S), (256 * S, 330 * S)], fill=gold, width=14 * S)
d.line([(256 * S, 168 * S), (198 * S, 212 * S)], fill=gold, width=12 * S)
d.line([(256 * S, 168 * S), (314 * S, 212 * S)], fill=gold, width=12 * S)
d.line([(256 * S, 262 * S), (208 * S, 298 * S)], fill=gold_dim, width=10 * S)
d.line([(256 * S, 262 * S), (304 * S, 298 * S)], fill=gold_dim, width=10 * S)

# base gem
gem = [(256, 340), (286, 380), (256, 420), (226, 380)]
d.polygon(pts(gem), fill=(120, 92, 47, 255))
d.line(pts(gem + [gem[0]]), fill=gold, width=4 * S, joint="curve")
d.polygon(pts([(256, 352), (274, 380), (256, 408), (238, 380)]), fill=(243, 215, 154, 255))

img = base.resize((W, W), Image.LANCZOS)
img.save("assets/icon.png")
img.resize((128, 128), Image.LANCZOS).save("ForeverHUD/Media/icon.tga", format="TGA")
print("ok", img.size)
