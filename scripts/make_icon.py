#!/usr/bin/env python3
"""Regenerate all raster icons from assets/logo.svg. Requires: pillow, cairosvg.
All output files share the exact same icon geometry. No artist redraws.
Run from repo root: python3 scripts/make_icon.py
"""
from pathlib import Path
from io import BytesIO
from PIL import Image
import cairosvg
base=Path('assets/logo.svg')
svg=base.read_bytes()
def raster(size):
    return Image.open(BytesIO(cairosvg.svg2png(bytestring=svg,output_width=size,output_height=size))).convert('RGBA')
img=raster(512);img.save('assets/icon.png')
Path('ForeverHUD/Media').mkdir(parents=True,exist_ok=True)
raster(128).save('ForeverHUD/Media/icon.tga',format='TGA')
print('ForeverHUD: icon.png (512) + icon.tga (128), same SVG master')
