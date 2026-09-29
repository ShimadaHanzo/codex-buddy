#!/usr/bin/env python3
"""Set the public update origin; never stores any credentials."""
import argparse, plistlib, re
from pathlib import Path
parser = argparse.ArgumentParser()
parser.add_argument('repository', help='OWNER/REPO')
args = parser.parse_args()
if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9][A-Za-z0-9._-]*', args.repository):
    parser.error('Expected OWNER/REPO, without URL or .git suffix')
if args.repository.endswith('.git'):
    parser.error('Omit the .git suffix')
path = Path(__file__).resolve().parents[1] / 'Info.plist'
with path.open('rb') as f:
    info = plistlib.load(f)
info['GitHubRepository'] = args.repository
with path.open('wb') as f:
    plistlib.dump(info, f, sort_keys=False)
print('Update repository configured:', args.repository)
