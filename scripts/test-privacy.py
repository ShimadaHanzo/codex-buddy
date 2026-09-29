#!/usr/bin/env python3
"""Synthetic leak fixtures; never open user credential files."""
from pathlib import Path
import subprocess, tempfile, shutil
root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='buddy-privacy-test-') as tmp:
    project = Path(tmp)
    (project / 'scripts').mkdir()
    shutil.copyfile(root / 'scripts/check-source.py', project / 'scripts/check-source.py')
    cases = {
        'auth.json': b'{}',
        '.env.production': b'CONFIG=example',
        'debug.log': b'synthetic log',
        'example.txt': b'sk-' + b'x' * 40,
        'home.txt': b'/' + b'Users/' + b'synthetic/' + b'file',
    }
    for name, value in cases.items():
        file = project / name; file.write_bytes(value)
        result = subprocess.run(['python3', str(project / 'scripts/check-source.py')], capture_output=True)
        assert result.returncode != 0, 'Leak not rejected: ' + name
        assert value not in result.stdout, 'Scanner printed secret content'
        file.unlink()
    (project / 'linked').symlink_to(project / 'missing', target_is_directory=True)
    assert subprocess.run(['python3', str(project / 'scripts/check-source.py')], capture_output=True).returncode != 0
    (project / 'linked').unlink()
    assert subprocess.run(['python3', str(project / 'scripts/check-source.py')], capture_output=True).returncode == 0
print('Synthetic privacy fixtures passed: credentials, env, logs, tokens, paths, symlinks')
