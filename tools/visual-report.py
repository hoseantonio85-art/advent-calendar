import base64
import html
import io
import shutil
from pathlib import Path
from PIL import Image

out = Path('build/visual-review')
out.mkdir(parents=True, exist_ok=True)
for folder in [Path('flutter/build/visual-qa'), Path('build/visual-qa')]:
    for source in folder.glob('*.png'):
        shutil.copy2(source, out / source.name)

for file in sorted(out.glob('*.png')):
    with Image.open(file) as image:
        buffer = io.BytesIO()
        image.convert('RGB').save(buffer, format='JPEG', quality=85, subsampling=0)
    encoded = base64.b64encode(buffer.getvalue()).decode()
    for i in range(0, len(encoded), 40000):
        print(f'ADVENT_JPEG|{file.stem}|{i//40000}|{encoded[i:i+40000]}')
    # Keep one exact PNG pair in the readable logs; every lossless original is
    # retained in the downloadable report. Avoid overflowing connector responses.
    if file.stem in ['calendar-390', 'reference-calendar-390']:
        encoded = base64.b64encode(file.read_bytes()).decode()
        for i in range(0, len(encoded), 40000):
            print(f'ADVENT_PNG|{file.stem}|{i//40000}|{encoded[i:i+40000]}')

cases = [p.stem for p in sorted(out.glob('*.png')) if not p.stem.startswith('reference-')]
panels = []
for case in cases:
    reference = out / f'reference-{case}.png'
    left = f'<img src="{reference.name}" alt="HTML {html.escape(case)}">' if reference.exists() else '<p>Дополнительное состояние Flutter; парный HTML-кадр в этом наборе не снят.</p>'
    panels.append(f'<section id="{case}"><h2>{html.escape(case)}</h2><div class="pair"><figure><figcaption>Утверждённый HTML</figcaption>{left}</figure><figure><figcaption>Flutter</figcaption><img src="{case}.png" alt="Flutter {html.escape(case)}"></figure></div></section>')
out.joinpath('index.html').write_text('''<!doctype html><html lang="ru"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Визуальная сверка Advent Calendar</title><style>body{font:15px system-ui;background:#f3f3ef;color:#23392c;margin:0;padding:24px}nav{display:flex;flex-wrap:wrap;gap:12px}h1{font-size:25px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px;max-width:940px}figure{margin:0}figcaption{margin-bottom:10px}img{display:block;max-width:100%;height:auto;border:1px solid #bbb}section{margin-top:36px}a{color:#235a44}p{max-width:800px}</style><h1>Повторная визуальная сверка Advent Calendar</h1><p>3 / 4 / 15 декабря 2026, 12:00 Europe/Moscow (дата указана в имени сценария; остальные — 15 декабря). Одинаковые локальные шрифты и reduced motion. В отчёте — PNG без потерь; в CI-логах — JPEG-превью и одна точная PNG-пара. Это инженерная проверка, не финальная приёмка на устройствах.</p><nav>''' + ''.join(f'<a href="#{c}">{html.escape(c)}</a>' for c in cases) + '</nav>' + ''.join(panels) + '</html>', encoding='utf-8')
print(f'VISUAL_REPORT: {len(cases)} Flutter states, {len(list(out.glob("reference-*.png")))} HTML states')
