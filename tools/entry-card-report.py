"""Before/after Flutter entry card only; no HTML/host screen is reproduced."""
import html
import shutil
from pathlib import Path
from PIL import Image, ImageDraw

source = Path('flutter/build/entry-card-qa')
out = Path('build/entry-card-review')
out.mkdir(parents=True, exist_ok=True)
for file in source.glob('*.png'):
    shutil.copy2(file, out / file.name)
panels = []
for width in [320, 360, 390, 430]:
    for state in ['normal', 'text200', 'festive']:
        case = f'{state}-{width}'
        before = out / f'before-{case}.png'
        after = out / f'after-{case}.png'
        with Image.open(before) as left, Image.open(after) as right:
            pair = Image.new('RGB', (left.width + right.width + 24, left.height + 36), '#e9ede8')
            draw = ImageDraw.Draw(pair)
            draw.text((12, 10), 'FLUTTER BEFORE (100%)', fill='#163c2b')
            draw.text((left.width + 36, 10), f'FLUTTER AFTER ({200 if state == "text200" else 100}%)', fill='#163c2b')
            pair.paste(left, (0, 36))
            pair.paste(right, (left.width + 24, 36))
            pair.save(out / f'comparison-{case}.png')
        panels.append(f'<section><h2>{html.escape(case)} dp</h2><img src="comparison-{case}.png" alt="Flutter before and after {case}"></section>')
out.joinpath('index.html').write_text('''<!doctype html><html lang="ru"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Входная карточка v9 — Flutter до/после</title><style>body{font:16px system-ui;background:#e9ede8;color:#163c2b;margin:24px}img{max-width:100%;height:auto}section{margin-top:32px}p{max-width:850px}</style><h1>Входная карточка v9 — Flutter до/после</h1><p>24 ноября 2026. Слева зафиксированный прежний Flutter, справа новая карточка. Локальные Yeseva One/Roboto; viewport 320/360/390/430 dp, поля demo 16 dp, PNG 2×. Это не HTML-эталон и не экран «ВторогоКрыла». Для text200 слева прежний вид при 100%, справа новый при 200%: старый виджет при 200% переполняется. Normal/festive сравниваются при одинаковых 100%. 38 дней — фиксированная тестовая величина; festive — 0.</p>''' + ''.join(panels) + '</html>', encoding='utf-8')
print('ENTRY_REVIEW: 12 before/after pairs, 4 viewport widths, normal/text200/festive')
