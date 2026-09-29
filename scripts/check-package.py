#!/usr/bin/env python3
"""Check the actual shipping app, not the developer's home directory."""
from pathlib import Path
import argparse, plistlib, re, subprocess
parser = argparse.ArgumentParser()
parser.add_argument('app', type=Path)
parser.add_argument('--dmg', type=Path)
args = parser.parse_args()
app = args.app
expected = {
    'Contents/Info.plist', 'Contents/MacOS/CodexBuddy',
    'Contents/Resources/AppIcon.icns', 'Contents/Resources/install-update.sh',
    'Contents/Resources/LICENSE.txt', 'Contents/_CodeSignature/CodeResources',
}
files = {str(p.relative_to(app)) for p in app.rglob('*') if p.is_file()}
assert files == expected, 'Unexpected or missing shipping files'
assert not any(p.is_symlink() for p in app.rglob('*')), 'Symlink in app'
size = sum((app / name).stat().st_size for name in files)
assert size < 10_000_000, 'App exceeds 10 MB budget'
info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
assert info['CFBundleIdentifier'] == 'com.duoduocat.codexbuddy', 'Unexpected app identity'
patterns = [
    rb'/(?:Users|home)/[A-Za-z0-9_.-]+/',
    rb'-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----',
    rb'(?:sk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{35,}|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})',
    rb'eyJ[A-Za-z0-9_-]{12,}\.[A-Za-z0-9_-]{12,}\.[A-Za-z0-9_-]{12,}',
]
for name in files:
    data = (app / name).read_bytes()
    assert not any(re.search(pattern, data) for pattern in patterns), 'Sensitive pattern in ' + name
subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
architectures = subprocess.check_output(['lipo', '-archs', str(app / 'Contents/MacOS/CodexBuddy')]).decode().strip()
assert architectures == 'arm64', 'Unexpected architecture'
print(f'Package passed: {len(files)} files, {size:,} bytes, arm64, valid signature')
if args.dmg:
    dmg_size = args.dmg.stat().st_size
    assert dmg_size < 8_000_000, 'DMG exceeds 8 MB budget'
    print(f'DMG size passed: {dmg_size:,} bytes')
