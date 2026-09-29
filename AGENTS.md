# Codex Buddy development

- Repository: duoduocats/codex-buddy. Bundle identifier: com.duoduocat.codexbuddy.
- Native AppKit/SwiftUI/URLSession only. Keep package lightweight; no bundled Codex CLI.
- Never read/copy local credentials into source, tests, screenshots, fixtures, releases or logs. Tests use synthetic data.
- User approval gate: build and install locally first. Wait for the user to explicitly confirm the local result before pushing, opening a PR, merging, tagging, or publishing a Release. This applies to every future change.
- Ordinary changes: feature/fix branch → tests/build → PR → merge main → version tag → draft Release → review and publish.
- Never enable important-update announcements unless the user explicitly requests a major-update popup. A major version number alone is NOT authorization. Default is silent.
- Important release marker: a standalone `<!-- codex-buddy:important -->` line in release notes. Only add with explicit user authorization.
- Users can always ignore a release. Never force install, auto-install without a user action, or block using an old version.
- Run `bash scripts/test.sh` and `BUILD_DIR=<fresh-temp-directory> bash build.sh` for code changes. Installer changes require staged-install/rollback tests.
- `scripts/prepare-release.py VERSION` prepares ordinary releases; use `--important` only when explicitly requested.
- Publish only this repository directory. Do not publish parent workspace, personal metadata, credential stores or local debug captures.
- Preserve GPL-3.0-only licensing and THIRD_PARTY_NOTICES.md.
