# Private On-Device iPad Manuscript Editor

This repository contains the authoritative product/security documentation package plus an actively building native Swift implementation for the private on-device iPad manuscript workflow.

Repository snapshot: native iPadOS-focused Swift codebase with a verified local test/build baseline, unsigned archive packaging evidence, and explicit release blockers still tracked in-repo.

- Shared Swift modules for secure vault, document import, revision handling, export, backup/restore, and local AI runtime boundaries
- SwiftUI app-shell target that builds for iOS Simulator and archives for unsigned iPad distribution packaging
- Metadata-only audit events and fail-closed lifecycle controls
- Per-project encrypted package storage with restore rollback protections
- Short-lived unlock-session control and Apple-platform vault selection
- Hardened local import foundations for text, DOCX, and PDF
- Apple on-device translation path wiring plus local model-bundle installer/runtime wiring with signed manifest verification, provenance/license checks, sealed-asset validation, and local containment controls
- Security-focused repository tests, retained simulator build evidence, and CI-enforced scan/build gates
- App-bundle packaging hygiene with launch screen resources, privacy manifest, and iPad app icon set wired into the native target
- Structured design-repository backbone for governance, product, UX, technical, data, AI, document, security, privacy, testing, implementation, and operations specs

## Current status

- Product stage: active implementation, foundation and several mid-stack controls completed
- Security review level: Level 2
- Release decision: BLOCKED
- Primary privacy promise: manuscript processing must remain on-device with no online path and no cloud fallback
- Translation architecture target: any approved supported language should be translatable to any other approved supported language; rollout starts with French proofreading/review and French to English, then French to Spanish, French to Portuguese, and French to Arabic

## Verified snapshot

- Package tests: `swift test --enable-code-coverage` -> `101 tests in 19 suites passed`
- Package line coverage: `63.90%`
- Simulator build: `xcodebuild -project YoanTranslatorApp.xcodeproj -scheme YoanTranslatorApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` -> `BUILD SUCCEEDED`
- Unsigned iPad archive: `xcodebuild -project YoanTranslatorApp.xcodeproj -scheme YoanTranslatorApp -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO archive -archivePath /tmp/YoanTranslatorApp.xcarchive` -> `ARCHIVE SUCCEEDED`
- Bundle inspection: `PrivacyInfo.xcprivacy`, launch-screen resources, and app icon metadata confirmed inside the archive

## Distribution blockers

- Physical iPad install/runtime validation has not been completed
- Airplane-mode and packet-capture privacy evidence is still missing
- Real `LocalAuthentication` / Keychain / Secure Enclave behavior is still unverified
- DOCX/PDF fidelity and page-preserving review quality on real samples are still incomplete
- Target-device proofreading and translation quality evidence is still incomplete
- Signing, final bundle identifier, and App Store Connect distribution setup remain outstanding

## What is implemented

- Repository documentation required by the design package
- `ManuscriptCore` package target with fail-closed security and AI-boundary types
- `ProjectVaultRepository` actor for create/list/unlock/lock/delete
- AES-GCM encryption for project payloads
- Project-scoped key-wrapping abstraction with Apple-platform vault selection
- Metadata-only audit log storage
- Canonical text/DOCX/PDF import foundations with adversarial tests
- Source snapshot persistence, revision-event storage, accept/reject/undo/restore foundations, and glossary validation
- Encrypted backup export/restore foundation with archive consistency and rollback checks
- Plaintext publishing-export staging with scoped confirmation enforcement and cleanup support
- SwiftUI app shell in `ManuscriptAppShell` with privacy-overlay, containment-policy, and import/export/backup wiring
- Repo and CI scan for forbidden cloud/analytics/network markers, entitlements, and obvious secret tokens
- Apple on-device Translation and Foundation Models proofreading execution paths with local bundled fallback wiring
- Signed local model-bundle installation, provenance/license validation, and bundled starter rules runtime

## What is not yet verified

- Native iPad signing, installation, and lifecycle behavior on physical hardware
- Real `LocalAuthentication` / Keychain / Secure Enclave integration
- App-switcher snapshot protection on device
- Airplane-mode and runtime network-capture evidence
- Full DOCX formatting fidelity on real manuscripts
- Safe PDF import and page-preserving extraction/translation review on real samples
- Publication-quality proofreading and translation accuracy validation on target devices
- Explicit local publishing export policy for user-approved `DOCX`/`PDF` output on device
- Production signer rotation/revocation policy and legal review for third-party model weights

## Documentation map

1. `AGENTS.md` - mandatory build and security workflow
2. `docs/00_governance/DOCUMENT_INDEX.md` - design repository index and source-of-truth map
3. `docs/01_product/PRD.md` - consolidated product requirements document
4. `docs/03_technical/TRD.md` - technical requirements baseline
5. `docs/03_technical/SYSTEM_DESIGN_DOCUMENT.md` - implementation-facing system design
6. `docs/05_data/ERD.md` and `docs/07_documents/CANONICAL_DOCUMENT_MODEL.md` - canonical data/document model
7. `docs/06_ai/AI_SYSTEM_SPECIFICATION.md` - AI-native processing contract
8. `docs/08_security/SECURITY_ARCHITECTURE.md` and `docs/security/SECURITY_REQUIREMENTS.md` - security design and controls
9. `docs/09_privacy/PRIVACY_REQUIREMENTS.md` - privacy guarantees and prohibitions
10. `docs/10_testing/MASTER_TEST_PLAN.md` - verification structure
11. `docs/11_implementation/DEFINITION_OF_DONE.md` - completion gate
12. `docs/12_operations/OPERATIONAL_RUNBOOK.md` - local operations and incident handling
13. `docs/12_operations/GITHUB_REPOSITORY_METADATA.md` - suggested GitHub description/topics and release snapshot text
14. Legacy focused docs under `docs/product`, `docs/architecture`, `docs/security`, `docs/implementation`, `docs/qa`, and `docs/operations`
15. `DECISION_LOG.md` - unresolved product and technical decisions

## Governing principle

The AI is non-authoritative. Deterministic code must remain responsible for authorization, decryption, mutation approval, export, deletion, and every other security-sensitive action.
