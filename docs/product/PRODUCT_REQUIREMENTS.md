# Product Requirements Document

## 1. Product summary

A private native iPad application for a manuscript owner to import, proofread, translate, edit, compare, approve, and export book-length text without transmitting manuscript content to any remote service.

## 2. Intended user

Initial release assumes one device owner and one local user. No accounts, teams, collaboration, remote administration, or multi-user sharing are included.

## 3. Core user outcomes

- Safely import a manuscript, including PDF manuscripts.
- Preserve an immutable original.
- Review spelling, grammar, consistency, and formatting issues, including French-source proofreading that preserves composition, meaning, and authorial intent.
- Generate on-device translation candidates for approved language pairs, with initial delivery starting from French to English.
- Receive line-editing suggestions without automatic replacement.
- Compare source, translation, and revisions.
- Accept or reject every substantive change.
- Export either an encrypted project archive or a deliberately decrypted final document.
- Delete a project and its key locally.

## 4. In scope for MVP

- Native SwiftUI interface optimized for iPad.
- Local project creation and unlock.
- DOCX, PDF, and UTF-8 text import.
- Safe internal manuscript representation.
- Immutable source snapshot.
- Local glossary and style guide.
- Deterministic validators for names, numbers, paragraph order, quotation consistency, formatting, missing segments, and source-composition preservation.
- Local spelling and basic grammar checks.
- Translation architecture designed to support any approved supported-language pair to any other approved supported-language pair.
- First release translation priority: French to English.
- Planned next rollout priorities after release hardening: French to Spanish, French to Portuguese, and French to Arabic.
- One on-device editing/review model path.
- Structured suggestions with accept/reject controls.
- Version history and rollback.
- Encrypted archive export.
- Authenticated decrypted export.
- Local privacy/audit events without manuscript content.

## 5. Explicitly out of scope for MVP

- User accounts or remote authentication.
- Cloud synchronization or backup.
- Collaboration or sharing inside the app.
- Web browsing, retrieval, email, messaging, publishing, or external tools.
- Model training on user content.
- Automatic publication-quality claims.
- OCR for scanned/image-only PDFs.
- Arbitrary model installation.
- Third-party keyboard integration.
- Background manuscript processing while the app is locked.

## 6. Functional requirements

### Project security

- The system must require device-owner authentication before decrypting a project.
- The system must automatically lock a project after inactivity and whenever the app enters the background.
- The original source snapshot must remain immutable.
- Each project must use a unique encryption key.

### Editing

- The system must represent model output as a proposal, not a direct mutation.
- The user must be able to inspect the original, proposal, rationale, category, and confidence/uncertainty indicator.
- Every accepted change must create a reversible revision event.
- French-source proofreading must improve grammar and correctness without silently changing structural composition, narrative intent, or factual meaning.

### Translation

- Translation must run on-device.
- The app must refuse the operation if the required model is absent or unavailable.
- The app must not route the text to any remote model.
- The system must preserve segment identifiers and formatting relationships.
- For PDF manuscripts, the system must preserve page boundaries for review and export mapping.
- The first supported translation direction is French to English.
- The long-term architecture must route between any approved supported source and target language pair without requiring a redesign of trust boundaries.
- Later language-pair additions must preserve review safety for right-to-left scripts where applicable, including Arabic.

### Import and export

- The importer must validate type, size, structure, and supported content.
- Active content, macros, scripts, external links, and unsupported embedded objects must be removed or rejected.
- Decrypted export must require explicit reauthentication and show the exact file and destination risk.
- The private vault copy and the user-approved publishing export must be treated as separate states.
- The app must support deliberate local publishing export to approved formats such as `DOCX` and `PDF` without introducing any online publication path.

## 7. Nonfunctional requirements

- Airplane-mode operation for all core workflows.
- No editing-time outbound network traffic.
- No manuscript text in logs, analytics, crash reports, or notifications.
- Graceful handling of low memory, unavailable models, malformed documents, interrupted processing, and low storage.
- Accessibility support for Dynamic Type, VoiceOver, keyboard navigation, contrast, and reduced motion.

## 8. Product acceptance criteria

The MVP cannot be considered complete until:

1. All core workflows function with network connectivity disabled.
2. Network inspection demonstrates no manuscript-processing outbound traffic.
3. Project isolation, lock, encryption, export, and deletion tests pass.
4. Malicious or malformed documents cannot execute code or alter policy.
5. Model output cannot overwrite content without user approval.
6. Cross-project leakage tests pass.
7. Translation/editing quality meets the benchmark thresholds defined in the QA plan.
8. All critical and high security tests pass.
9. PDF manuscript import and page-by-page translation review work without cloud processing.
