"""Convert the original Windows ICO into Apple's light/dark app icon assets.
Requires Pillow only when regenerating; generated assets are committed.
"""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
catalog = ROOT / 'WinampClassic/Assets.xcassets'
target = catalog / 'AppIcon.appiconset'
target.mkdir(parents=True, exist_ok=True)
source = Image.open(ROOT / 'tools/assets/WinampIcon.ico').convert('RGBA')
# Retain the entire original artwork, including the white diamond and outline.
logo = source.resize((880, 880), Image.Resampling.LANCZOS)
light = Image.new('RGBA', (1024, 1024), (244, 244, 247, 255))
light.alpha_composite(logo, (72, 72))
light.convert('RGB').save(target / 'AppIcon-Light.png')
# iOS supplies the dark background behind the transparent foreground artwork.
dark = Image.new('RGBA', (1024, 1024))
dark.alpha_composite(logo, (72, 72))
dark.save(target / 'AppIcon-Dark.png')
info = {'author': 'xcode', 'version': 1}
(catalog / 'Contents.json').write_text(json.dumps({'info': info}, indent=2)+'\n')
(target / 'Contents.json').write_text(json.dumps({'images': [
    {'filename': 'AppIcon-Light.png', 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'},
    {'appearances': [{'appearance': 'luminosity', 'value': 'dark'}],
     'filename': 'AppIcon-Dark.png', 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'}
], 'info': info}, indent=2)+'\n')
preview = Image.new('RGB', (560, 300), (60, 62, 68))
dark_preview = Image.new('RGBA', (1024, 1024), (28, 28, 30, 255))
dark_preview.alpha_composite(dark)
for x, icon in [(20, light), (300, dark_preview)]:
    preview.paste(icon.convert('RGB').resize((240, 240), Image.Resampling.LANCZOS), (x, 15))
draw = ImageDraw.Draw(preview)
draw.text((110, 270), 'LIGHT', fill='white')
draw.text((395, 270), 'DARK', fill='white')
preview.save(ROOT / 'app-icon-preview.png')
print('Generated original-logo light/dark icon assets (1024x1024).')
