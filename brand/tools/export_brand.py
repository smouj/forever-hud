#!/usr/bin/env python3
"""Export brand raster formats from canonical vector files (no fonts needed)."""
from pathlib import Path
from io import BytesIO
from PIL import Image
import cairosvg

root = Path(__file__).resolve().parents[2]
pairs = [
 ('assets/logo.svg','assets/icon.png',512,512),
 ('assets/logo.svg','brand/exports/foreverhud-symbol-white-1024.png',1024,1024),
 ('brand/masters/foreverhud-lockup-horizontal-white.svg','brand/exports/foreverhud-lockup-horizontal-white.png',1530,430),
 ('brand/masters/foreverhud-lockup-stacked-white.svg','brand/exports/foreverhud-lockup-stacked-white.png',1000,920),
 ('brand/social/open-graph-1200x630.svg','brand/social/open-graph-1200x630.png',1200,630),
 ('brand/social/avatar-dark-tile.svg','brand/social/avatar-dark-tile-512.png',512,512),
 ('brand/social/cover-transparent-white.svg','brand/social/cover-transparent-white-1500x500.png',1500,500),
 ('assets/banner.svg','brand/social/github-readme-banner-1280x320.png',1280,320),
]
for size in [16,24,32,48,64,128,256,512]:
 pairs.append(('assets/logo.svg',f'brand/exports/foreverhud-symbol-white-{size}.png',size,size))
for src,dst,w,h in pairs:
 p=root/dst;p.parent.mkdir(parents=True,exist_ok=True)
 p.write_bytes(cairosvg.svg2png(bytestring=(root/src).read_bytes(),output_width=w,output_height=h))
 Image.open(p).verify()
print('Wrote', len(pairs),'PNG exports')
img=Image.open(root/'brand/exports/foreverhud-symbol-white-128.png').convert('RGBA')
img.save(root/'ForeverHUD/Media/icon.tga',format='TGA')
img=Image.open(root/'brand/exports/foreverhud-symbol-white-1024.png').convert('RGBA')
img.save(root/'brand/exports/foreverhud-symbol-white-1024.webp',format='WEBP',lossless=True)
img.resize((256,256),Image.Resampling.LANCZOS).save(root/'brand/exports/foreverhud-icon.ico',format='ICO',sizes=[(16,16),(32,32),(48,48),(64,64),(128,128),(256,256)])
print('Wrote WoW icon.tga, WebP and ICO')
