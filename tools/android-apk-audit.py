"""Measure actual APK contents; do not impose a size budget or modify assets."""
import argparse
import hashlib
import json
import zipfile
from collections import defaultdict
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument('--debug', required=True)
p.add_argument('--debug-arm64', required=True)
p.add_argument('--release', required=True)
p.add_argument('--profile', required=True)
p.add_argument('--out', required=True)
p.add_argument('--inventory-from')
p.add_argument('--signing-report')
a = p.parse_args()
out = Path(a.out); out.mkdir(parents=True, exist_ok=True)

def category(name):
    if name.endswith('/libflutter.so'): return 'Flutter engine'
    if name.endswith('/libapp.so'): return 'Dart AOT'
    if name.endswith('kernel_blob.bin'): return 'Dart debug kernel'
    if name.endswith(('.ttf', '.otf')): return 'Fonts'
    if name.endswith(('.webp', '.png', '.jpg', '.jpeg')): return 'Images'
    if name.endswith('.dex'): return 'Android DEX / plugins'
    if name.startswith('assets/flutter_assets/'): return 'Other Flutter assets'
    return 'Android shell / other'

def inspect(path):
    path = Path(path); data = path.read_bytes()
    groups = defaultdict(lambda: {'compressed': 0, 'uncompressed': 0, 'files': 0})
    with zipfile.ZipFile(path) as z:
        entries = [i for i in z.infolist() if not i.is_dir()]
        for i in entries:
            g = groups[category(i.filename)]
            g['compressed'] += i.compress_size; g['uncompressed'] += i.file_size; g['files'] += 1
        duplicates = defaultdict(list)
        for i in entries:
            if category(i.filename) == 'Images':
                duplicates[hashlib.sha256(z.read(i)).hexdigest()].append({'path': i.filename, 'bytes': i.file_size})
        qa_files = [i.filename for i in entries if '/test/' in i.filename or 'integration_test' in i.filename or 'visual-qa' in i.filename]
    return {'file': path.name, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
        'abis': sorted({i.filename.split('/')[1] for i in entries if i.filename.startswith('lib/') and i.filename.endswith('.so')}),
        'categories': dict(groups), 'largest': [{'path': i.filename, 'bytes': i.file_size} for i in sorted(entries, key=lambda x: x.file_size, reverse=True)[:15]],
        'identical_images': [v for v in duplicates.values() if len(v) > 1], 'qa_files': qa_files}

reports = {name: inspect(getattr(a, name.replace('-', '_'))) for name in ['debug', 'debug-arm64', 'release', 'profile']}
assert reports['release']['abis'] == ['arm64-v8a'], reports['release']['abis']
assert reports['debug-arm64']['abis'] == ['arm64-v8a']
assert reports['profile']['abis'] == ['arm64-v8a']
assert not reports['release']['qa_files'], reports['release']['qa_files']
assert 'Dart debug kernel' not in reports['release']['categories']
assert 'Dart AOT' in reports['release']['categories']

if a.inventory_from:
    inventory = json.loads(Path(a.inventory_from).read_text())['images']
else:
    assets = Path('flutter/assets')
    references = json.loads((assets / 'advent/calendar_2026.json').read_text(encoding='utf-8'))['assets']
    used = set(references.values()) | {'assets/advent/entry_fir_v9.webp'}
    inventory = []
    for f in sorted(assets.rglob('*')):
        if f.is_file() and f.suffix.lower() == '.webp':
            inventory.append({'path': 'assets/' + f.relative_to(assets).as_posix(), 'bytes': f.stat().st_size,
                'sha256': hashlib.sha256(f.read_bytes()).hexdigest(), 'referenced': 'assets/' + f.relative_to(assets).as_posix() in used})
result = {'apks': reports, 'images': inventory, 'notes': [
    ('Release/profile ARM64 use the persistent demo certificate; not production.' if a.signing_report else 'Build-local debug certificate only; persistent demo signing happens in trusted publication CI.'),
    'Universal debug vs ARM64 release changes both build mode and ABI. Debug ARM64 controls the ABI difference.',
    'ZIP compressed sums exclude ZIP/signing/alignment overhead; libflutter.so may be stored uncompressed.',
    'Byte-identical images are retained aliases pending Issue #7, without recompression or visual changes.',
    'No artificial size target is imposed. Physical-device performance is not inferred from APK size.']}
if a.signing_report: result['signing'] = json.loads(Path(a.signing_report).read_text())
(out / 'apk-size-report.json').write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding='utf-8')
lines = ['# Test APK size audit', '', '| Build | Bytes | MiB | ABIs |', '|---|---:|---:|---|']
for name, r in reports.items(): lines.append(f"| {name} | {r['bytes']} | {r['bytes']/1048576:.2f} | {', '.join(r['abis'])} |")
lines += ['', '| APK category | Debug ARM64, uncompressed | Release ARM64, uncompressed |', '|---|---:|---:|']
for name in sorted(set(reports['debug-arm64']['categories']) | set(reports['release']['categories'])):
    lines.append(f"| {name} | {reports['debug-arm64']['categories'].get(name,{}).get('uncompressed',0)} | {reports['release']['categories'].get(name,{}).get('uncompressed',0)} |")
lines += ['', '## Interpretation', ''] + ['- ' + n for n in result['notes']]
lines += ['', '## Resource inventory', '']
for i in inventory: lines.append(f"- {i['path']}: {i['bytes']} bytes; {'referenced' if i['referenced'] else 'not referenced by content/entry'}; SHA {i['sha256'][:12]}")
lines += ['', 'Full exact sizes, duplicate groups, largest files and hashes are in apk-size-report.json.', '']
(out / 'apk-size-report.md').write_text('\n'.join(lines), encoding='utf-8')
print('\n'.join(lines[:10]))
