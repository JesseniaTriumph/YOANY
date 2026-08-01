# Sequential Build Plan

This is the exact recommended construction order. A later step must not be used to compensate for a missing earlier security boundary.

## Current snapshot - 2026-08-01

- Release state: `BLOCKED`
- Security review level: `Level 2`
- Completed foundations: native app target builds, unsigned iPad archive packaging, launch screen/privacy manifest/app icon bundle wiring, encrypted vault lifecycle, lifecycle privacy state coordination, canonical text/DOCX/PDF import foundations, revision/event model, encrypted backup restore foundation, plaintext export staging controls, Apple on-device translation/proofreading gateway wiring with bundled fallback, local bundle-backed starter model runtime, signed external model-bundle verification, staged review acceptance flow, baseline test coverage, and CI-enforced repository capability/build checks
- Remaining release-critical work: DOCX formatting fidelity, deeper PDF validation with real-sample review, model quality evaluation, page-preserving translation review, richer editor/review UI, device privacy/network evidence, and real-device recovery/export validation
- Newly closed oversight: external model imports now require signed directory bundles whose complete installed asset inventory is declared and digest-validated before persistence
- Active caution: do not treat the current starter rules model as evidence of publication-quality proofreading or translation capability
- Private tester path: Xcode Personal Team sideloading is now the intended no-cost handoff route until paid Apple distribution is justified

## Foundation

1. `Done` Create Xcode project and native SwiftUI target.
2. `Done` Define forbidden-capability policy and dependency allowlist.
3. `Done` Add CI checks for forbidden SDKs, hosts, entitlements, and secrets.
4. `Done` Define domain types: `ProjectID`, `SegmentID`, `RevisionID`, `ModelID`, `ExportConfirmation`.
5. `Done` Define security errors and fail-closed state machine.
6. `Done` Implement metadata-only local logging wrapper.
7. `Partially done` Implement app background/snapshot protection in shared/runtime shell state; real-device evidence still required.

## Vault and identity

8. `Done` Implement `LocalAuthentication` abstraction.
9. `Done` Implement project unlock-session actor.
10. `Partially done` Implement cryptographic key generation and Keychain wrapping; physical-device verification remains open.
11. `Done` Implement authenticated encryption service.
12. `Done` Implement encrypted project package format and version manifest.
13. `Done` Implement project create/list/lock/unlock/delete with synthetic empty data.
14. `Done` Add lock, key, corruption, replay, and deletion tests.

## Safe document core

15. `Done` Define canonical document/segment/formatting schema, including page mapping for PDF sources.
16. `Done` Build UTF-8 text parser.
17. `Partially done` Build constrained DOCX ZIP/XML reader; richer formatting fidelity remains open.
18. `Partially done` Build constrained PDF reader and text-layer extractor; real-sample confidence remains open.
19. `Partially done` Add file-signature, size, count, decompression-ratio, relationship, PDF object, and page/resource validation.
20. `Done` Build quarantine and cleanup lifecycle.
21. `Done` Persist immutable source snapshot.
22. `Done` Add malicious and interrupted import tests.

## Editing and revision integrity

23. `Done` Build read-only source viewer baseline.
24. `Partially done` Build working revision view; richer editor/review UX remains open.
25. `Done` Implement structured diff and `RevisionEvent` store.
26. `Done` Implement accept, reject, undo, and restore foundations.
27. `Done` Implement glossary and style-guide entities.
28. `Done` Implement deterministic validators.
29. `Done` Add direct-call, cross-project, revision-integrity, and log-leak tests.

## AI boundary before AI model

30. `Done` Define `ModelRole` and strict input/output schemas.
31. `Done` Implement model adapter protocol with a fake deterministic model.
32. `Done` Implement bounded-context selector.
33. `Partially done` Implement operation budgets, cancellation, timeout, concurrency, and memory policy; production model telemetry-free device profiling remains open.
34. `Done` Implement output validator, meaning/composition-change classification, and proposal-only pipeline.
35. `Done` Add prompt-injection, malformed-output, conservative-proofreading, and unavailable-model tests using fake models.

## First on-device model

36. `Blocked for release` Select and license-review proofreading/editing model.
37. `Blocked for release` Convert/package model for Core ML or supported on-device framework.
38. `Done for bundle trust, incomplete for release` Add signed model manifest and digest verification, including full asset-inventory coverage for external bundles.
39. `Partially done` Implement offline adapter/runtime; Apple on-device translation and proofreading are wired as the primary local paths on supported devices, but target-device quality evidence and the bundled rules engine fallback still require release validation.
40. `Blocked for release` Run privacy, performance, thermal, memory, and adversarial tests on target hardware.
41. `Blocked for release` Compare model suggestions against synthetic/human-reviewed corpus and set acceptance thresholds.
42. `Blocked for release` Define signer rotation, signer retirement, offline revocation/update handling, and rollback policy for distributable model bundles.

## Translation

43. `Blocked for release` Package and benchmark the French proofreading and French-to-English translation paths on target hardware.
44. `Done for initial route selection, blocked for release evidence` Use Apple on-device Translation as the initial French-to-English execution path and Apple Foundation Models as the initial French proofreading execution path; retain target-device quality and availability evidence before release.
45. `Partially done` Implement segmentation, page mapping, and context window strategy.
46. `Done` Implement glossary constraints.
47. `Partially done` Implement semantic and deterministic translation QA foundations.
48. `Blocked for release` Build side-by-side and page-by-page review with issue flags.
49. `Blocked for release` Run benchmark, edge-case, long-document, PDF-page-alignment, right-to-left, and device-performance tests.

## Export and recovery

50. `Done` Implement encrypted archive creation.
51. `Done` Implement archive integrity verification and restore.
52. `Partially done` Implement reauthentication-bound export confirmation; real native prompt/handoff evidence remains open.
53. `Partially done` Implement decrypted text export and secure temp cleanup; DOCX/PDF publishing export remains open.
54. `Blocked for release` Verify backup, Files app, provider, preview, clipboard, and indexing behavior on device.
55. `Done` Implement incident containment switches for model roles and import/export features.

## Release hardening

56. `In progress` Run full unit, integration, UI, adversarial, privacy, accessibility, and performance suites; unit/adversarial/repository-build coverage is automated, but device/privacy/accessibility/performance evidence remains open.
57. `Partially done` Inspect app binary and bundle for forbidden hosts, SDKs, entitlements, and symbols; repository and project-source enforcement is automated, and unsigned archive bundle inspection now covers launch screen/privacy manifest/app icon presence, but final device/app-bundle/network inspection remains open.
58. `Blocked for release` Verify model and dependency provenance, license, digest, signer lifecycle, and rollback.
59. `Pending` Conduct external security review where feasible.
60. `Done` Finalize privacy notice, threat model, incident playbooks, and evidence matrix.
61. `Current decision: BLOCKED` Issue `READY`, `CONDITIONAL`, or `BLOCKED` based on evidence.
62. `Gate` Release only if all critical/high requirements are verified on target devices with retained evidence.
63. `Done for private test prep` Document a no-cost Personal Team sideload path with explicit install prerequisites, device acceptance checks, and retained-evidence requirements.
