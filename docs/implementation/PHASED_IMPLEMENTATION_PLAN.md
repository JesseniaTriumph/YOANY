# Phased Implementation Plan

Each phase has an entry gate, deliverables, security work, verification, and exit gate. Do not begin AI feature development before the local vault, safe document model, and security test harness exist.

## Phase 0 - Product decisions and feasibility

### Goals

Resolve the few decisions that materially affect architecture.

### Deliverables

- Initial language pair(s): Architecture designed for any approved supported pair; first rollout is French proofreading plus French to English, then French to Spanish, French to Portuguese, and French to Arabic
- Supported iPad hardware and minimum OS
- Distribution method
- MVP file formats: DOCX, plain text, and PDF with page-preserving review
- Privacy promise and prohibited capabilities
- Model licensing shortlist
- Synthetic benchmark corpus plan

### Exit gate

All open decisions that affect model size, deployment, or data handling have an owner and provisional answer.

## Phase 1 - Secure native shell and project lifecycle

### Build

- SwiftUI app shell
- App lifecycle lock behavior
- LocalAuthentication integration
- Project repository interfaces
- Per-project key creation/wrapping
- Encrypted empty project package
- Metadata-only local audit events
- Forbidden dependency and network-host checks

### Security verification

- Unlock/lock tests
- Background snapshot protection
- No-network baseline
- Key-access and deletion tests

### Exit gate

A project can be securely created, locked, unlocked, and deleted without manuscript import.

## Phase 2 - Safe document import and internal representation

### Build

- DOCX, text, and constrained PDF import adapters
- Quarantine and limits
- Safe parser
- Segment tree and formatting model
- Immutable source snapshot
- Import diagnostics

### Security verification

- Malformed files
- Malformed or hostile PDFs
- Archive bombs
- Path traversal
- External relationships and active content
- Interrupted import recovery

### Exit gate

Synthetic manuscripts import safely, preserve structure, and cannot execute or fetch external content.

## Phase 3 - Editor, revisions, and deterministic QA

### Build

- Chapter/segment editor
- Structured revision events
- Accept/reject/undo
- Internal clipboard
- Local glossary/style guide
- Names, numbers, negation, segment, and formatting validators

### Security verification

- Direct mutation bypass attempts
- Revision integrity
- Cross-project isolation
- Logging and temporary-file inspection

### Exit gate

Manual editing is safe and fully reversible before any AI is introduced.

## Phase 4 - On-device proofreading model

### Build

- Typed model adapter
- Bounded context coordinator
- Structured suggestion schema
- Local spelling/grammar rules
- Composition-preservation guardrails for source-language proofreading
- One approved small model
- Cancellation, timeout, memory limits

### Security verification

- Prompt injection
- Malformed output
- model unavailable
- no cloud fallback
- package tampering

### Exit gate

AI may propose corrections but cannot mutate content or cross project boundaries.

## Phase 5 - Translation pipeline

### Build

- One language-pair model: French to English
- Stable segment mapping
- Glossary injection
- Back/semantic comparison
- Translation review interface
- Quality flags

### Security and quality verification

- Benchmark corpus
- Names/numbers/negation preservation
- Missing/duplicate/reorder detection
- PDF page-alignment preservation
- Long-document consistency
- Memory and thermal tests

### Exit gate

Translation meets defined quality thresholds and all failures are visible and recoverable.

## Phase 6 - Export, archive, and deletion completion

### Build

- Encrypted project archive
- Restore validation
- Decrypted DOCX/text export
- Exact confirmation and reauthentication
- Secure temporary-file lifecycle
- Complete deletion flow

### Security verification

- Replay/substitution tests
- Wrong destination warnings
- backup/indexing inspection
- deletion and restore tests

### Exit gate

Exports and deletion behave correctly under normal, interrupted, and adversarial conditions.

## Phase 7 - Full adversarial review and release hardening

### Work

- Complete AI threat matrix testing
- Dependency and model supply-chain review
- Static analysis and secret scan
- App bundle host/SDK scan
- Performance and accessibility testing
- Incident-response drills
- Privacy policy and user-facing claims review

### Exit gate

No critical/high blocker remains; all claims match evidence; release decision can become READY or CONDITIONAL.

## Phase 8 - Post-MVP additions

Each requires Level 2 reassessment:

- Additional languages
- EPUB/PDF/OCR
- Model downloads
- Sync or collaboration
- Multiple users
- Cloud backup
- External publishing
- Analytics or support diagnostics
