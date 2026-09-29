# 质量与发布审计 / Quality and release audit

## 自动门禁 / Automated gates

| Area | Gate |
| --- | --- |
| Availability | Quota decoding, missing data, extreme timestamps; synthetic success/401/403/429/500/timeout/offline/malformed-response/missing-credentials tests; version comparison and update notification policy |
| Recovery | Disposable installer tests for success, replacement failure, and launch-command failure |
| Update package | Real DMG fixture download, SHA-256, read-only mount, app identity/version, signature, tamper rejection |
| Resource use | Single-flight requests, bounded timeouts, failure backoff (60–960 seconds), timer tolerance, cached menu image |
| Size | App < 10,000,000 bytes; DMG < 8,000,000 bytes; exactly six shipping files; arm64; no bundled CLI/runtime |
| Privacy | Working files + all reachable Git history scan; secret/path patterns; PNG metadata; credential/log/database filenames; symlinks |
| Scanner regression | Synthetic secrets only; checks detection and prevents printing secret values |
| Native UI | Demo-only status item, panel open/close, settings smoke test on a GUI Mac |

Run `bash scripts/test.sh`, `python3 scripts/check-source.py --history`, then `bash scripts/package.sh`. GitHub CI builds and audits the actual app; Release also stages the real DMG in an isolated temporary directory. Never publish the parent workspace.

## 本机性能复核 / Local performance check

Launch the built executable with `--performance-check` for a 60-second synthetic idle sample. It does not load local credentials or check updates. Output contains CPU and peak resident memory only. Use `--ui-check` for native UI smoke tests; screenshots use `--snapshot` with synthetic data.

A short idle sample is not a long-running soak test or a measurement of every Mac. Investigate sustained idle CPU above 1%, repeated memory growth, unexpected child processes, and repeated requests. Repeat after significant drawing, timer, or networking changes. Timer tolerance follows [Apple energy guidance](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/Timers.html).

## 发布前仍需人工验证 / Manual release matrix

- macOS 13 fallback material and macOS 26+ Liquid Glass on real systems; multiple displays, scale factors, full-screen spaces, light/dark appearance.
- System locale, timezone, 12/24-hour format, accessibility/VoiceOver, login-item registration and approval.
- Sleep/wake, Wi-Fi loss/recovery, expired authentication, GitHub throttling/outages, long-running memory stability.
- Real published-release download/relaunch, read-only installation, insufficient storage, user cancellation. Fixtures do not prove live GitHub connectivity.
- Installer rollback covers a failing launch command. `open` success does not prove the relaunched application remains healthy; post-launch crash recovery is not yet implemented.
- Current releases are ad hoc signed, not Apple-notarized. Digest and ad hoc verification do not authenticate an independent publisher. A future Developer ID/notarization workflow needs separate setup.
- ChatGPT quota endpoint behavior is an external dependency and can change. No absolute availability or zero-leak guarantee is claimed.

## 公开内容 / Public content

Use only synthetic screenshots. Review README, release notes, package contents, commit author/committer addresses, and metadata before publishing. Automated pattern scans cannot identify every possible personal detail. The chosen public GitHub account and noreply identity are intentional. English and Simplified Chinese documentation and UI are available; the UI follows macOS preferred languages.

## 本轮结果 / Local audit results (2026-09-29)

- Synthetic idle sample: 63.0 seconds, average CPU 0.29%, peak resident memory 78.1 MiB on the development Mac. This excludes live network polling and does not measure long-term memory growth.
- Locally built bilingual app: 2,237,140 bytes; DMG: 1,769,698 bytes. CI artifacts may differ slightly by compiler version. Six files in the signed app; package and source privacy gates passed.
- Native UI smoke checks passed: status item, panel open/close, settings.
- Unit, network-failure, privacy-fixture, replacement/rollback, real-DMG staging and tamper-rejection tests passed locally.
- Source scan and all currently reachable local history passed known secret/path pattern checks. No real credentials were read for this audit's tests.
- Bilingual README and privacy/security documentation are published in the public repository. GitHub description and ChatGPT / Codex topics have been configured.
