# Sequence Diagrams

## Import Sequence

`User -> UI -> ImportController -> QuarantineStore -> FormatValidator -> Parser -> CanonicalDocument -> VaultRepository -> AuditLog`

Ordering:

1. User selects file
2. UI opens security-scoped access
3. Import controller copies only needed local input into quarantine
4. Validator checks size/type/format constraints
5. Parser produces canonical document
6. Vault persists immutable source snapshot
7. Audit log records metadata-only completion

## Apple Notes Ingestion Sequence

`User -> Notes Share Or Copy Action -> App Intake UI -> ImportController -> QuarantineStore Or Text Intake -> CanonicalDocument -> VaultRepository -> AuditLog`

Ordering:

1. User explicitly shares or copies note content into the app
2. Intake UI accepts local handed-off content only
3. Import controller validates the handed-off payload
4. Canonical document is created from note text or attached file content
5. Vault persists immutable source snapshot

## Proofreading Sequence

`User -> ReviewUI -> WorkflowController -> VaultRepository -> ContextSelector -> RuleEngine -> ProofreadingAdapter -> OutputValidator -> ReviewUI -> RevisionStore`

Ordering:

1. User selects proofreading scope
2. Controller retrieves only authorized local segments
3. Deterministic checks run first
4. Local model proposes corrections
5. Validator enforces meaning/composition flags
6. User accepts or rejects
7. Accepted changes become revision events

## Translation Sequence

`User -> ReviewUI -> WorkflowController -> VaultRepository -> PageSegmentMapper -> GlossaryProvider -> TranslationAdapter -> OutputValidator -> PageReviewUI -> RevisionStore`

Ordering:

1. User selects source and target route
2. Controller verifies approved local route exists
3. Mapper preserves page and segment identity
4. Glossary context is injected minimally
5. Local model proposes translation
6. Validator checks names/numbers/structure/page alignment
7. User reviews page by page
8. Accepted changes become revision events

## Export Sequence

`User -> ExportUI -> WorkflowController -> Authenticator -> ExportConfirmationStore -> ExportRenderer -> LocalFileHandoff -> CleanupService -> AuditLog`

Ordering:

1. User requests export
2. Reauthentication succeeds
3. Exact export confirmation is issued
4. Renderer creates local output
5. File is handed off to local destination
6. Temporary plaintext is removed
7. Audit event is recorded
