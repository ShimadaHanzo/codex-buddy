#!/usr/bin/env python3
import os, re, plistlib
from pathlib import Path
root=Path(__file__).resolve().parents[1]
tag=os.environ['RELEASE_TAG']
assert re.fullmatch(r'v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)',tag), 'Invalid stable tag'
with (root/'Info.plist').open('rb') as f:info=plistlib.load(f)
assert info['CFBundleShortVersionString']==tag[1:], 'Tag and app version differ'
assert info['CFBundleIdentifier']=='com.duoduocat.codexbuddy', 'Unexpected bundle identifier'
assert info['GitHubRepository']==os.environ['EXPECTED_REPOSITORY'], 'Unexpected update repository'
assert (root/'LICENSE').read_text().startswith('                    GNU GENERAL PUBLIC LICENSE'), 'GPL license missing'
notes=(root/'releases'/f'{tag}.md').read_text()
assert '请填写本次变更' not in notes, 'Finish release notes before publishing'
marker='<!-- codex-buddy:important -->'
if os.environ.get('IMPORTANT')=='true' and marker not in notes.splitlines():notes=marker+'\n\n'+notes
(root/'dist').mkdir(exist_ok=True)
(root/'dist/release-notes.md').write_text(notes)
if os.environ.get('GITHUB_OUTPUT'):
 with open(os.environ['GITHUB_OUTPUT'],'a') as f:f.write('tag='+tag+'\n')
print('Validated release',tag,'important:',marker in notes.splitlines())
