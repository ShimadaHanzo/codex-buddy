#!/usr/bin/env python3
"""Audit only this publishable project. Output paths/rule names, never values."""
from pathlib import Path
import re, sys, subprocess
root = Path(__file__).resolve().parents[1]
errors = []
patterns = {
    'private-key': rb'-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----',
    'token': rb'(?:sk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{35,}|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})',
    'local-home': rb'/(?:Users|home)/[A-Za-z0-9_.-]+/',
    'jwt': rb'eyJ[A-Za-z0-9_-]{12,}\.[A-Za-z0-9_-]{12,}\.[A-Za-z0-9_-]{12,}',
}
for p in root.rglob('*'):
    rel = p.relative_to(root)
    if any(part in {'.git', 'build', 'dist', '.swiftpm'} for part in rel.parts):
        continue
    if p.is_symlink():
        errors.append((str(rel), 'symlink'));continue
    if not p.is_file(): continue
    if (p.name.startswith('.env.') and p.name != '.env.example') or p.name in {'auth.json', '.env', 'id_rsa', 'id_ed25519', '.DS_Store', '.netrc', '.npmrc', '.pypirc'} or p.suffix in {'.p12', '.pfx', '.key', '.pem'}:
        errors.append((str(rel), 'credential-file'))
    data = p.read_bytes()
    if p.suffix.lower() in {'.log', '.jsonl', '.sqlite', '.sqlite3', '.db'}:
        errors.append((str(rel), 'local-data-file'))
    if data.startswith(b'\x89PNG'):
        offset = 8
        while offset + 12 <= len(data):
            size = int.from_bytes(data[offset:offset+4], 'big')
            kind = data[offset+4:offset+8]
            if kind in {b'eXIf', b'tEXt', b'zTXt', b'iTXt'}:
                errors.append((str(rel), 'image-metadata'))
            offset += size + 12
    for name, pattern in patterns.items():
        if re.search(pattern, data):errors.append((str(rel), name))
# Scan tracked content even when ignored by the working-tree filters above.
if '--history' in sys.argv:
    seen = set()
    for commit in subprocess.check_output(['git', '-C', str(root), 'rev-list', '--all']).decode().splitlines():
        for row in subprocess.check_output(['git', '-C', str(root), 'ls-tree', '-r', commit]).decode().splitlines():
            meta, path = row.split('\t', 1)
            mode, kind, sha = meta.split()
            historic = Path(path)
            if historic.name in {'auth.json', '.env', 'id_rsa', 'id_ed25519', '.netrc', '.npmrc', '.pypirc'} or historic.suffix.lower() in {'.p12', '.pfx', '.key', '.pem', '.log', '.jsonl', '.sqlite', '.sqlite3', '.db'} or (historic.name.startswith('.env.') and historic.name != '.env.example'):
                errors.append((path, 'history-private-file'))
            if mode == '120000': errors.append((path, 'history-symlink'))
            if kind != 'blob' or sha in seen: continue
            seen.add(sha)
            data = subprocess.check_output(['git', '-C', str(root), 'cat-file', 'blob', sha])
            for name, pattern in patterns.items():
                if re.search(pattern, data): errors.append((path, 'history-' + name))
    print(f'History scanned: {len(seen)} unique blobs')
if errors:
    for path, rule in errors:print(f'{rule}: {path}')
    sys.exit(1)
print('Publishable source scan passed')
