#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${OUTPUT_DIR:-$ROOT/dist}"
RELEASE_BUILD="${BUILD_DIR:-$(mktemp -d /private/tmp/codex-buddy-release.XXXXXX)}"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$ROOT/Info.plist")
BUILD_DIR="$RELEASE_BUILD" bash "$ROOT/build.sh"
python3 "$ROOT/scripts/check-package.py" "$RELEASE_BUILD/Codex Buddy.app"
mkdir -p "$OUT"
STAGE=$(mktemp -d /private/tmp/codex-buddy-stage.XXXXXX)
trap 'rm -rf "$STAGE"' EXIT
# The stage is always a newly created temporary directory owned by this script.
ditto "$RELEASE_BUILD/Codex Buddy.app" "$STAGE/Codex Buddy.app"
ln -s /Applications "$STAGE/Applications"
cp "$ROOT/README.md" "$STAGE/安装说明.txt"
NAME="Codex-Buddy-$VERSION-arm64.dmg"
hdiutil create -volname 'Codex Buddy' -srcfolder "$STAGE" -format UDZO -fs HFS+ -ov "$OUT/$NAME"
(cd "$OUT" && shasum -a 256 "$NAME" > "$NAME.sha256")
python3 "$ROOT/scripts/check-package.py" "$RELEASE_BUILD/Codex Buddy.app" --dmg "$OUT/$NAME"
echo "$OUT/$NAME"
