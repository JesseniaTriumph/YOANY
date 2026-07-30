# GitHub Repository Metadata and Release Snapshot

Last updated: 2026-07-30
Status owner: local repository state

## Suggested GitHub repository description

Private on-device iPad manuscript editor and translation workspace with local-only AI, encrypted project vaults, hardened import/export controls, and native Swift/iPadOS packaging.

## Suggested topics

- `ipad`
- `ipados`
- `swift`
- `swiftui`
- `translation`
- `proofreading`
- `offline-ai`
- `local-first`
- `privacy`
- `encryption`
- `document-processing`
- `manuscript-editor`

## Release snapshot

- Product stage: active implementation
- Security review level: Level 2
- Latest release recommendation: BLOCKED
- Verified package tests: `101 tests in 19 suites passed`
- Verified package line coverage: `63.90%`
- Verified simulator build: `xcodebuild ... generic/platform=iOS Simulator` -> `BUILD SUCCEEDED`
- Verified unsigned archive: `xcodebuild ... generic/platform=iOS archive` -> `ARCHIVE SUCCEEDED`
- Verified bundle resources: launch screen, privacy manifest, and app icon metadata present in archive

## Blocking items before a distribution claim

- Physical iPad install and runtime evidence
- Real `LocalAuthentication` and Keychain behavior validation
- Airplane-mode and network-capture proof
- Real manuscript DOCX and PDF fidelity validation
- Translation and proofreading quality validation on target hardware
- Production signer rotation/revocation operations
- Final signing team, bundle identifier, and App Store Connect configuration

## Notes

- The local repository has been initialized, committed, and pushed to `origin/main`.
- Remote GitHub metadata was not updated from the CLI because the local `gh` authentication token is invalid and requires reauthentication before direct repository-settings changes can be made.
