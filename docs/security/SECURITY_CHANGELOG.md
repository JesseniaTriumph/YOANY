# Security Changelog

## 2026-08-01 - Private tester sideload handoff documentation

- Review level: Level 2
- Trigger: The immediate distribution need shifted away from App Store / TestFlight toward a no-cost private iPad install, and the repository lacked a controlled tester-handoff procedure that distinguished Xcode sideload readiness from actual release readiness
- New requirements: The repository must document a deterministic Personal Team sideload path, required device prerequisites, on-device smoke checks, and retained evidence so that private testing does not overstate product readiness or bypass known privacy/security blockers
- Controls implemented: added `docs/12_operations/PERSONAL_TEAM_SIDELOAD_GUIDE.md`, added `docs/12_operations/TESTER_DEVICE_ACCEPTANCE_CHECKLIST.md`, expanded `docs/12_operations/RELEASE_CHECKLIST.md` with physical-device handoff gates, and updated the sequential build plan to make Personal Team sideloading the current no-cost tester-distribution track
- Tests run: pending in this change entry until post-edit verification completes
- Remaining risks: this change documents the sideload path but does not itself provide real-device privacy, quality, or network-isolation evidence; overall release readiness remains blocked until those device tests are actually run
- Release decision: BLOCKED

## 2026-07-30 - Repository release snapshot tightening and app-shell support split

- Review level: Level 2
- Trigger: The repository had been pushed to GitHub, but its top-level presentation still understated the current verified build evidence and the largest UI shell file remained oversized enough to obscure coverage and maintenance work
- New requirements: Repository-facing release notes must accurately state verified local evidence and remaining distribution blockers, while app-shell support scaffolding should be split from the main shell file without altering trust boundaries or runtime behavior
- Controls implemented: extracted `AppShellEnvironment` and related support/view-data types into `Sources/ManuscriptAppShell/AppShellSupport.swift`, added `docs/12_operations/GITHUB_REPOSITORY_METADATA.md` with a concrete GitHub description/topics/release snapshot, and tightened `README.md` to distinguish verified build/archive evidence from unresolved release blockers
- Tests run: `scripts/scan_forbidden_capabilities.sh .` -> `passed`; `swift test --enable-code-coverage` -> `101 tests in 19 suites passed`; `xcrun llvm-cov report ...` -> package line coverage `63.90%`; `xcodebuild -project YoanTranslatorApp.xcodeproj -scheme YoanTranslatorApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` -> `BUILD SUCCEEDED`; `xcodebuild -project YoanTranslatorApp.xcodeproj -scheme YoanTranslatorApp -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO archive -archivePath /tmp/YoanTranslatorApp.xcarchive` -> `ARCHIVE SUCCEEDED`; archive inspection confirmed bundled `PrivacyInfo.xcprivacy`, `Base.lproj/LaunchScreen.storyboardc`, and iPad icon metadata in `Info.plist`
- Remaining risks: physical-device privacy/runtime evidence, network-capture proof, quality validation, and GitHub remote metadata updates remain incomplete; direct remote repository settings changes still require valid GitHub CLI authentication
- Release decision: BLOCKED

## 2026-07-30 - Security-helper and domain coverage expansion

- Review level: Level 2
- Trigger: Coverage audit showed that several small security and domain support files still lacked direct deterministic test evidence, while aggregate package coverage was being dragged down by a very large app-shell surface and unexercised key-wrapping helper paths
- New requirements: Local authentication token behavior, filesystem key wrapping, capability-aware keychain wrapping paths, incident containment helpers, glossary lookup behavior, and foundational security/domain model initialization must have direct automated coverage evidence in addition to indirect usage through larger workflows
- Controls implemented: new `SecurityAndDomainSupportTests` covering token freshness, local-only authenticator issuance, filesystem key wrapping success and mismatch rejection, capability-aware keychain wrapping paths, incident containment helper behavior, case-insensitive glossary resolution, and security/domain model initialization checks
- Tests run: `scripts/scan_forbidden_capabilities.sh .` -> `passed`; `swift test --enable-code-coverage` -> `101 tests in 19 suites passed`; `xcrun llvm-cov report ...` -> package line coverage `63.90%`; `xcodebuild -project YoanTranslatorApp.xcodeproj -scheme YoanTranslatorApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` -> `BUILD SUCCEEDED`
- Remaining risks: The dominant uncovered surface remains `AppShell.swift` and `AppleOnDeviceAIAdapter.swift`, plus environment-dependent real-device security and quality evidence; aggregate repository coverage is improved but not near 100% because large UI and platform-bound paths are still only partially testable in this environment
- Release decision: BLOCKED

## 2026-07-30 - Distribution package hardening for iPad archive readiness

- Review level: Level 2
- Trigger: TestFlight-style distribution preparation exposed that the native app target still omitted explicit launch-screen and privacy-manifest resources from the bundle, shipped no populated app icon catalog, and retained stale alternate app-entry scaffolding that could obscure release packaging state
- New requirements: The iPad app bundle must archive cleanly with explicit local bundle resources for launch screen, privacy manifest, and app icons; the repository must keep a single unambiguous app entrypoint; and release/status documentation must distinguish archive-readiness from still-blocked signing, device, and quality evidence
- Controls implemented: explicit resource wiring for `Assets.xcassets`, `PrivacyInfo.xcprivacy`, and `LaunchScreen.storyboard` in `YoanTranslatorApp.xcodeproj`; generated iPad app icon catalog contents; empty-data/no-tracking privacy manifest; removal of stale alternate `@main` scaffolding files; launch-storyboard build-setting wiring; and archive-content verification for `Info.plist`, `PrivacyInfo.xcprivacy`, compiled launch-screen resources, and icon metadata
- Tests run: `scripts/scan_forbidden_capabilities.sh .` -> `passed`; `swift test` -> `92 tests in 18 suites passed`; `xcodebuild -project YoanTranslatorApp.xcodeproj -scheme YoanTranslatorApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` -> `BUILD SUCCEEDED`; `xcodebuild -project YoanTranslatorApp.xcodeproj -scheme YoanTranslatorApp -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO archive -archivePath /tmp/YoanTranslatorApp.xcarchive` -> `ARCHIVE SUCCEEDED`; archive inspection confirmed bundled `PrivacyInfo.xcprivacy`, `Base.lproj/LaunchScreen.storyboardc`, and app icon metadata in `Info.plist`
- Remaining risks: Apple signing/team setup, non-placeholder distribution identifier, App Store Connect configuration, device-install/runtime evidence, export-compliance/legal review, and the broader model/privacy/quality release blockers remain incomplete
- Release decision: BLOCKED

## 2026-07-30 - Apple on-device translation gateway hardening and testable fallback wiring

- Review level: Level 2
- Trigger: The initial French-to-English production path was already conceptually Apple-local, but the shell instantiated the Apple gateway directly without test seams, and translation availability checks still relied on session readiness instead of explicit installed-versus-supported route preflight
- New requirements: The initial French-to-English production execution path must remain strictly local, preflight installed language availability without prompting implicit downloads, and be testable as a primary gateway with deterministic fallback to the signed local bundled runtime when unavailable
- Controls implemented: `OnDeviceAIGateway` abstraction, environment-injected Apple gateway wiring, explicit `LanguageAvailability.status(from:to:)` route preflight before translation, Apple-primary and bundled-fallback translation tests, and updated release/security planning to distinguish Apple translation readiness from the still-blocked proofreading model path
- Tests run: `swift test` -> `90 tests in 18 suites passed`; `xcodebuild -project YoanTranslatorApp.xcodeproj -scheme YoanTranslatorApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` -> `BUILD SUCCEEDED`
- Remaining risks: Real-device Apple translation quality, language-pack installation behavior, page-preserving review UX, production proofreading model selection, device privacy/network evidence, and signer lifecycle operations remain incomplete
- Release decision: BLOCKED

## 2026-07-30 - Apple on-device proofreading gateway hardening and fallback verification

- Review level: Level 2
- Trigger: The Apple Foundation Models proofreading path already existed, but it still lacked explicit Apple-primary versus bundled-fallback shell verification and was not yet recorded as a first-class release-path decision alongside translation
- New requirements: The initial French proofreading execution path must remain strictly local, prefer Apple Foundation Models on supported devices, and retain deterministic bundled fallback behavior when the Apple path is unavailable
- Controls implemented: Apple-primary proofreading shell test coverage, bundled-fallback proofreading shell test coverage, and updated release/security planning to distinguish implemented Apple proofreading wiring from the still-unverified target-device quality and release evidence
- Tests run: `swift test` -> `92 tests in 18 suites passed`; `xcodebuild -project YoanTranslatorApp.xcodeproj -scheme YoanTranslatorApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` -> `BUILD SUCCEEDED`
- Remaining risks: Real-device Apple proofreading quality, composition-preservation behavior on long manuscripts, device privacy/network evidence, and page-preserving review UX remain incomplete
- Release decision: BLOCKED

## 2026-07-30 - Containment policy enforcement, signer revocation handling, sealed external model-bundle assets, CI gate enforcement, and release-plan reconciliation

- Review level: Level 2
- Trigger: External model installation still allowed undeclared files to be copied inside a signed directory bundle, signer lifecycle handling still lacked explicit revocation enforcement, incident-response containment controls were still only documented, repository policy checks were not yet enforced in CI, and build/status documents were understating implemented controls while failing to call out remaining release gates precisely
- New requirements: Every non-hidden file installed from an external local model bundle must be declared in the signed manifest with a matching digest, manifest-only external installs are no longer accepted, revoked signer IDs must be rejected before install, local kill switches must be able to disable AI roles, import routes, decrypted export, restore, and model installation without code changes, repository changes must fail CI when they introduce forbidden network/analytics markers, entitlements, or obvious secrets, and release-planning documents must reflect actual implementation state and remaining device/model/security evidence
- Controls implemented: complete directory-bundle asset enumeration and digest validation before persistence, explicit rejection for undeclared bundle assets, external manifest-only install rejection, trust-store revoked-signer handling, shell revoked-signer messaging, shell import-type restriction to bundle directories, shared containment-policy types, app-shell containment enforcement for AI/model/import/export/restore actions, negative containment tests, broadened forbidden-capability scanning for entitlements and secret markers, CI workflow enforcement for scan plus test/build verification, release evidence matrix creation, private-edition privacy notice creation, updated sequential build plan, expanded traceability matrix, refreshed README status, and refreshed security status
- Tests run: `swift test` -> `88 tests in 18 suites passed`; `xcodebuild -project YoanTranslatorApp.xcodeproj -scheme YoanTranslatorApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` -> `BUILD SUCCEEDED`
- Remaining risks: Production signer rotation/revocation, legal review for real third-party model weights, true neural-model runtime integration, device-performance validation, richer DOCX/PDF fidelity review, and no-network/device-privacy evidence remain incomplete
- Release decision: BLOCKED

## 2026-07-29 - Trusted signer enforcement for external model manifests

- Review level: Level 2
- Trigger: External model bundles still lacked cryptographic signer attestation and trusted-key verification
- New requirements: External model manifests must carry signing metadata, the signed payload must match a canonical manifest digest, required bundle assets must have declared digests, and external installs must verify against a built-in trusted signer allowlist before any local persistence occurs
- Controls implemented: `signerKeyID`, `signatureAlgorithm`, `signedPayloadDigest`, and `manifestSignature` manifest fields; deterministic canonical-payload signing for installer verification; built-in trusted signer allowlist; rejection paths for missing signature declaration, unsupported signature algorithms, untrusted signers, invalid signature encoding, digest mismatches, failed signature verification, and missing required asset digests; signed-manifest installer tests; and shell error handling for the new attestation failures
- Tests run: `swift test` -> `81 tests in 18 suites passed`; `xcodebuild -project YoanTranslatorApp.xcodeproj -scheme YoanTranslatorApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` -> `BUILD SUCCEEDED`
- Remaining risks: Trusted-key verification is now enforced for the current local allowlist, but production signer rotation, offline revocation/update strategy, legal review for real third-party model weights, true neural-model runtime integration, device-performance validation, and no-network/device-privacy evidence remain incomplete
- Release decision: BLOCKED

## 2026-07-29 - External model provenance and license enforcement

- Review level: Level 2
- Trigger: External local model installation still accepted bundles without deterministic license and provenance evidence
- New requirements: External model installs must declare license and provenance in the manifest, directory bundles must carry `LICENSE.txt` and `PROVENANCE.json`, and provenance metadata must match the installed model identity
- Controls implemented: installer rejection for missing license declaration, missing provenance declaration, missing provenance asset, invalid provenance document, digest-validated `LICENSE.txt` and `PROVENANCE.json` assets, provenance-document consistency checks against manifest identity, installed-model metadata exposure in the shell, and added tests for positive install, missing-license rejection, missing-provenance rejection, digest mismatch, and visible shell metadata
- Tests run: `swift test` -> `80 tests in 18 suites passed`; `xcodebuild -project YoanTranslatorApp.xcodeproj -scheme YoanTranslatorApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` -> `BUILD SUCCEEDED`
- Remaining risks: Manifest-level provenance assertions are now enforced, but cryptographic signature verification for third-party bundles, legal review of real model licenses, true neural-model runtime integration, device-performance validation, and no-network/device-privacy evidence remain incomplete
- Release decision: BLOCKED

## 2026-07-29 - Offline model bundle runtime and demo installer

- Review level: Level 2
- Trigger: The on-device AI runtime and model installation path were materially expanded from manifest-only preview behavior to a validated local bundle-backed execution path
- New requirements: Installed model bundles must decode older manifests safely, reject unsupported backends, require expected local assets for bundle-backed execution, and verify asset digests before use
- Controls implemented: `OnDeviceModelManifest` backward-compatible decoding, `bundle-rules-v1` runtime backend, SHA-256 asset digest verification, explicit unsupported-backend and missing-asset failures, installed-model status discovery, bundled offline starter model installation, app-shell model installation/status wiring, and positive/negative tests for manifest compatibility, asset loading, digest mismatch rejection, and visible shell status updates
- Tests run: `swift test` -> `78 tests in 18 suites passed`; `xcodebuild -project YoanTranslatorApp.xcodeproj -scheme YoanTranslatorApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` -> `BUILD SUCCEEDED`
- Remaining risks: The runtime is now a real local bundle-backed rules engine, but true production neural inference, formal model provenance review for third-party weights, license verification for real open-source models, device-performance validation, and no-network capture evidence remain incomplete
- Release decision: BLOCKED

## 2026-07-28 - Initial architecture definition

- Review level: Level 2
- Trigger: New on-device AI capability, file import/export, offline architecture, encrypted storage, and iPad platform decision
- New requirements: Native iPadOS, no cloud processing, per-project encryption, local model isolation, malicious file handling, human-controlled edits, export/deletion confirmation
- Controls implemented: Documentation only
- Tests run: None; no codebase exists
- Remaining risks: All controls unimplemented and unverified; model selection and distribution unresolved
- Release decision: BLOCKED

## 2026-07-28 - Phase 1 secure foundation scaffold

- Review level: Level 2
- Trigger: Initial implementation of encrypted project-vault storage, unlock-session control, authentication abstraction, audit logging, and repo capability scanning
- New requirements: Project lifecycle must fail closed when authentication, key access, or payload integrity checks fail
- Controls implemented: `ProjectVaultRepository`, AES-GCM payload encryption, project-scoped key-wrapping abstraction, actor-isolated unlock-session controller, metadata-only audit events, forbidden capability scan script, security-oriented tests
- Tests run: Test files added for unlock access control, tampered package rejection, corrupted ciphertext rejection, delete flow, and metadata-only audit logging
- Remaining risks: Real iPad `LocalAuthentication`, Keychain/Secure Enclave wrapping, app lifecycle snapshot protection, network capture evidence, and actual test execution remain unverified in the current environment
- Release decision: BLOCKED

## 2026-07-28 - Scope clarification for PDF and French translation roadmap

- Review level: Level 2
- Trigger: User requirement added a new document format and fixed the initial translation rollout order
- New requirements: PDF manuscripts are in scope; PDF translation review must preserve page boundaries; French to English is the first release language pair, followed by French to Spanish and French to Portuguese
- Controls implemented: Documentation updates only
- Tests run: None
- Remaining risks: PDF parsing/extraction, page mapping, and translation-model selection remain unimplemented and unverified
- Release decision: BLOCKED

## 2026-07-28 - Arabic added to planned follow-on translation languages

- Review level: Level 2
- Trigger: User requirement added a right-to-left follow-on translation language
- New requirements: French to Arabic joins the planned post-release language pairs and requires explicit bidirectional-text and right-to-left review validation
- Controls implemented: Documentation updates only
- Tests run: None
- Remaining risks: Arabic model selection, font/layout behavior, bidi rendering safety, and review UX remain unimplemented and unverified
- Release decision: BLOCKED

## 2026-07-28 - Multi-direction architecture and conservative French proofreading clarified

- Review level: Level 2
- Trigger: User requirement clarified that supported languages should be translatable in any approved direction and that French proofreading must preserve composition, accuracy, and intent
- New requirements: Translation architecture must support any approved language pair; first rollout remains French proofreading plus French to English; French proofreading must conservatively improve grammar without silent composition drift
- Controls implemented: Documentation updates only
- Tests run: None
- Remaining risks: language-direction routing, pair-specific model strategy, composition-preservation validators, and proofreading evaluation remain unimplemented and unverified
- Release decision: BLOCKED

## 2026-07-28 - No online path and explicit local publishing export clarified

- Review level: Level 2
- Trigger: User requirement clarified that online access must not affect the manuscript path and that export is allowed only through deliberate local handoff
- New requirements: Manuscript processing must have no online path whatsoever; local publishing export to approved formats is allowed only by explicit user action outside the encrypted vault
- Controls implemented: Documentation updates only
- Tests run: None
- Remaining risks: export confirmation flow, temp-file cleanup, and runtime no-network verification remain unimplemented and unverified
- Release decision: BLOCKED

## 2026-07-28 - Design repository backbone and canonical text import foundation

- Review level: Level 2
- Trigger: Missing formal design artifacts were added and the first canonical document-core implementation step began
- New requirements: Implementation must follow the structured design repository and canonical page/segment model
- Controls implemented: document index and specification backbone, canonical document entities, page/segment IDs, plain-text import with page preservation and bounded warnings
- Tests run: New tests added for plain-text import segmentation, page boundary preservation, encoding rejection, and oversized segment warning behavior
- Remaining risks: tests are present but not executed in this environment; DOCX/PDF import, source snapshot persistence, and revision integration remain incomplete
- Release decision: BLOCKED

## 2026-07-28 - Additional control specifications for state, sequencing, isolation, runtime, revision, and restore

- Review level: Level 2
- Trigger: Additional architecture documents were required to keep implementation from inventing sensitive behavior
- New requirements: State transitions, sequence ordering, project isolation, model runtime, revision handling, and backup/restore behavior must be treated as explicit contracts
- Controls implemented: formal specs added for lifecycle states, sequence flows, project isolation, model runtime/update/rollback, revision engine, and backup/restore
- Tests run: None
- Remaining risks: these contracts are documented but not yet fully implemented
- Release decision: BLOCKED

## 2026-07-28 - Import coordinator and local export foundations

- Review level: Level 2
- Trigger: New import and export workflow code added for manuscript-bearing document handling
- New requirements: Imports must flow through quarantine and file-type detection; unsupported formats must fail closed; local publishing export rendering must stay local
- Controls implemented: import request/result contracts, quarantine staging, file format detection, PDF local import adapter path, fail-closed DOCX behavior, text export renderer
- Tests run: New tests added for import coordinator plain-text success, unsupported binary rejection, and DOCX fail-closed behavior
- Remaining risks: DOCX parser, robust PDF validation, export confirmation/reauth path, and test execution remain incomplete
- Release decision: BLOCKED

## 2026-07-28 - Apple Notes considered as a local ingestion boundary

- Review level: Level 2
- Trigger: User requested iPad Notes be considered as an input source
- New requirements: Notes support must use explicit local handoff and not rely on undocumented private storage formats
- Controls implemented: Product, technical, architecture, and security docs updated
- Tests run: None
- Remaining risks: Concrete Notes intake UI and adapter path are not yet implemented
- Release decision: BLOCKED

## 2026-07-28 - Workspace service and export confirmation contracts

- Review level: Level 2
- Trigger: Product workflow code added for project workspace editing and export confirmation semantics
- New requirements: Notes text intake and user-edit acceptance must flow through the same controlled workspace path; export confirmations must be validated against exact project/revision/destination scope
- Controls implemented: Notes text importer, project workspace service, export confirmation validator, workspace and confirmation tests
- Tests run: New tests added for notes intake, workspace user edits, and export confirmation expiration/matching
- Remaining risks: Native Notes share UI, DOCX/PDF publishing renderers, and runtime test execution remain incomplete
- Release decision: BLOCKED

## 2026-07-29 - DOCX text extraction importer added

- Review level: Level 2
- Trigger: A new supported document format moved from fail-closed placeholder to real import implementation
- New requirements: DOCX import must safely extract importable text from local OpenXML packages without introducing network or active-content behavior
- Controls implemented: local ZIP entry reader, constrained `word/document.xml` extraction, XML paragraph parsing into canonical segments, DOCX importer tests, coordinator integration
- Tests run: automated Swift tests for direct DOCX import and coordinator DOCX import
- Remaining risks: relationships/media/macros/object handling and richer formatting fidelity are still incomplete
- Release decision: BLOCKED

## 2026-07-29 - Hardened PDF constraints and encrypted archive foundation

- Review level: Level 2
- Trigger: PDF validation and backup/restore workflow code added
- New requirements: encrypted PDFs, oversized PDFs, and missing text layers must fail closed; encrypted archive export/restore must validate integrity and project collisions
- Controls implemented: PDF limits and encrypted-PDF rejection, archive container/integrity checks, restore collision handling, archive tests, PDF importer tests
- Tests run: automated Swift tests for archive export/restore and PDF import behavior
- Remaining risks: richer PDF structural validation, publishing PDF export, and portable cross-device key restoration remain incomplete
- Release decision: BLOCKED

## 2026-07-29 - AI proposal and glossary validation foundations

- Review level: Level 2
- Trigger: AI-facing proposal models and conservative validation rules were added
- New requirements: proofreading proposals must be rejectable when they overreach composition/meaning bounds; translation proposals must honor glossary constraints
- Controls implemented: glossary model, language routes, structured AI proposal model, proposal validator, deterministic preview runtime coverage, and AI validation tests
- Tests run: automated Swift tests for proofreading overreach rejection, glossary violation rejection, and deterministic runtime proposal generation
- Remaining risks: production on-device model adapters and richer semantic validation remain incomplete
- Release decision: BLOCKED

## 2026-07-29 - Confirmed local publishing export staging

- Review level: Level 2
- Trigger: Decrypted local publishing export flow added beyond raw text rendering
- New requirements: publishing export materialization must require a valid scoped confirmation, remain revision-bound, avoid plaintext project-title leakage in staging paths, and support deterministic cleanup of staged plaintext
- Controls implemented: `LocalPublishingExportService`, confirmation validation on export materialization, revision-state binding, fail-closed unsupported-format rejection, opaque staging paths, and cleanup support for staged plaintext files
- Tests run: automated Swift tests for successful plain-text export, cleanup, revision-race rejection, unsupported-format rejection, and destination-mismatch rejection
- Remaining risks: native share-sheet handoff, destination-class warnings in UI, DOCX/PDF publishing renderers, device backup/indexing inspection, and runtime test execution in this environment remain incomplete
- Release decision: BLOCKED

## 2026-07-29 - DOCX active-content rejection and export replay protection

- Review level: Level 2
- Trigger: Hardened supported document import and high-impact decrypted export confirmation handling
- New requirements: DOCX packages must reject path traversal, macros, external relationships, and embedded payload structures before parsing; publishing-export confirmations must be single-use to resist replay
- Controls implemented: ZIP path validation, forbidden DOCX entry rejection, `.rels` inspection for external targets, single-use export confirmation tracking, and adversarial tests for both import and export boundaries
- Tests run: automated Swift tests for DOCX macro rejection, embedded-payload rejection, external-relationship rejection, path-traversal rejection, and export-confirmation replay rejection
- Remaining risks: richer DOCX formatting fidelity, compressed-entry/decompression-ratio handling, native destination warnings, and device-level verification remain incomplete
- Release decision: BLOCKED

## 2026-07-29 - PDF preflight hardening

- Review level: Level 2
- Trigger: Hardened PDF import boundary for malicious or ambiguous local documents
- New requirements: PDF import must reject malformed headers/EOF, active-content markers, and oversized object/stream graphs before text extraction
- Controls implemented: raw PDF preflight validation for `%PDF-` and `%%EOF`, forbidden active-content marker rejection, object-count limit, stream-count limit, and adversarial PDF importer tests
- Tests run: automated Swift tests for active-content rejection, malformed EOF rejection, object-limit rejection, and stream-limit rejection
- Remaining risks: deeper PDF object graph validation, real-sample page-map confidence checks, and device-level PDFKit behavior remain incomplete
- Release decision: BLOCKED

## 2026-07-29 - Export confirmation kind binding

- Review level: Level 2
- Trigger: Exact-action export confirmation scope was still missing format binding required by the security specification
- New requirements: export confirmations must bind export kind/format in addition to project, revision, destination, and expiration
- Controls implemented: `ExportConfirmation` now carries `ExportKind`, validator enforces kind matching, and local publishing export refuses mismatched confirmation kind
- Tests run: automated Swift tests for validator kind mismatch and export-service kind mismatch rejection
- Remaining risks: native destination-class warnings, reauthentication UI, and on-device handoff verification remain incomplete
- Release decision: BLOCKED

## 2026-07-29 - Exact-project deletion confirmation

- Review level: Level 2
- Trigger: Project deletion path still relied on fresh authentication without an exact-project confirmation token
- New requirements: project deletion must require a time-bounded confirmation bound to the exact project identity in addition to reauthentication
- Controls implemented: `DeleteConfirmation`, `DeleteConfirmationValidator`, repository deletion confirmation enforcement, and negative tests for mismatched and expired delete confirmations
- Tests run: automated Swift tests for delete-confirmation validator success/expiry/project mismatch and repository delete rejection on mismatched or expired confirmation
- Remaining risks: native deletion UI, cache/preview cleanup on device, and real lifecycle/privacy validation remain incomplete
- Release decision: BLOCKED

## 2026-07-29 - Restore rollback hardening

- Review level: Level 2
- Trigger: Encrypted archive restore could leave imported key state behind if final package persistence failed partway through restore
- New requirements: failed restore must leave no partial vault file or imported wrapped-key state behind
- Controls implemented: staged restore package write, wrapped-key import only during finalize, rollback cleanup of staging artifact and imported key on restore failure
- Tests run: automated Swift tests for successful restore, duplicate-project rejection, and failed key-import restore rollback with no partial state left behind
- Remaining risks: native restore UI, destination warnings, cross-device key portability, and device-level backup/indexing validation remain incomplete
- Release decision: BLOCKED

## 2026-07-29 - Archive manifest consistency validation

- Review level: Level 2
- Trigger: Restore accepted archives based on outer integrity without verifying that the manifest matched the enclosed package metadata
- New requirements: archive restore must reject unsupported manifest versions and manifest/package metadata mismatches before any local state is accepted
- Controls implemented: archive format-version gate, manifest-to-package validation for project identity, package timestamps, and payload digest, plus adversarial restore tests for tampered manifest fields
- Tests run: automated Swift tests for manifest project mismatch rejection and unsupported archive-version rejection
- Remaining risks: deeper semantic validation of plaintext manifest summary fields and cross-device recovery UX remain incomplete
- Release decision: BLOCKED

## 2026-07-29 - Lifecycle lock and snapshot-obscuring state machine

- Review level: Level 2
- Trigger: Native lifecycle/privacy behavior remained documented but not represented in deterministic shared runtime code
- New requirements: inactive scenes must obscure snapshots; backgrounding and auth invalidation must lock the active project; lifecycle state must be queryable by the native shell
- Controls implemented: `AppLifecycleSecurityCoordinator`, explicit scene-phase/lock-reason state model, background lock behavior, inactivity/auth-invalidation lock handling, and app-shell scene-phase integration
- Tests run: automated Swift tests for inactive snapshot obscuring, background lock, inactivity timeout, auth invalidation, and active-state recovery
- Remaining risks: actual iPadOS snapshot APIs, scene wiring in a real app target, and device-level lifecycle/privacy evidence remain incomplete
- Release decision: BLOCKED

## 2026-07-29 - Native app build verification, filesystem vault runtime, shell privacy overlay, backup flow, and export warning UI

- Review level: Level 2
- Trigger: Native app target and app-shell runtime moved from unverified scaffolding to a buildable local application path
- New requirements: the Apple-platform runtime must prefer platform credential storage for wrapped project keys; security status must track actual native build evidence rather than pre-build assumptions
- Controls implemented: `YoanTranslatorApp.xcodeproj` native target wiring, successful simulator build verification, `AppShellEnvironment` filesystem-only wrapped-key storage for the live app environment, app-shell storage-selection coverage, shell rendering of lifecycle-driven privacy obscuring state during inactive/background phases, local encrypted backup export/restore actions backed by repository archive validation, explicit backup-file picker restore flow, and a two-step native plaintext export warning/arming flow before decrypted handoff
- Tests run: automated Swift tests including app-shell storage-selection, lifecycle-state, encrypted-backup export coverage, backup-picker presentation coverage, and plaintext-export arming enforcement, plus native `xcodebuild` simulator build verification for `YoanTranslatorApp`
- Remaining risks: physical-iPad Keychain inspection, LocalAuthentication prompt behavior on device, app-switcher snapshot obscuring evidence on hardware, cross-device recovery validation, signing/team configuration for device deployment, and network/privacy capture evidence remain incomplete
- Release decision: BLOCKED
