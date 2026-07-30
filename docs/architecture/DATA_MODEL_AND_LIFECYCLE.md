# Data Model and Lifecycle

## 1. Core entities

### Project

- Opaque project ID
- User-visible title stored encrypted
- Creation and modification timestamps
- Project encryption-key reference
- Security policy version
- Model/benchmark versions used

### SourceSnapshot

- Immutable original content
- Import format and hash
- Segment tree
- Page map for page-oriented formats such as PDF
- Formatting map
- Import warnings

### Segment

- Stable ID
- Chapter/section/paragraph/sentence relationships
- Encrypted text
- Formatting attributes
- Source-language metadata

### RevisionEvent

- Prior segment version reference
- Proposed and accepted change
- Category
- Human decision
- Timestamp
- Model/rule version
- No hidden chain-of-thought storage

### GlossaryEntry

- Source term
- Approved target term
- Scope
- Notes
- Version

### AuditEvent

Metadata only:

- Event type
- Project opaque ID
- Timestamp
- Result code
- Security-control version
- Never manuscript text, prompts, outputs, titles, or external file paths

## 2. Data classification

| Data | Classification | Storage |
|---|---|---|
| Manuscript and revisions | Highly sensitive | Project-encrypted vault |
| Glossary, character bible, style guide | Highly sensitive | Project-encrypted vault |
| Model suggestions | Highly sensitive | Project-encrypted vault or ephemeral memory |
| Project title | Confidential | Encrypted |
| Model weights | Internal/licensed artifact | Read-only app/model package |
| Audit metadata | Internal | Protected local store |
| Encryption keys | Critical secret | Keychain-protected wrapping |

## 3. Lifecycle

### Collection

Only user-selected files and user-entered project metadata are collected. No behavioral analytics or remote identifiers.

### Processing

Plaintext exists only while the project is unlocked and only for the selected scope. Models receive minimum necessary context.

### Retention

Project data remains until explicit local deletion. The app must not create undisclosed retention copies.

### Deletion

Destroy the project key, delete encrypted project files, remove cached previews and temporary artifacts, and record completion metadata. Do not claim guaranteed physical overwrite on flash storage.

### Backup

MVP supports user-initiated encrypted archive export. Automatic cloud backup is excluded. App file backup eligibility must be explicitly reviewed and configured.

### Publishing export

Decrypted publishing export is a deliberate local handoff outside the encrypted vault. It must require explicit user action, exact confirmation, and temporary plaintext cleanup after handoff.

## 4. Clipboard and screen exposure

- Prefer internal clipboard for manuscript text.
- Disable or restrict copy for protected views where viable.
- Obscure app-switcher snapshots.
- Do not place text in notifications.
- Warn against third-party keyboards with Full Access.

## 5. Import source warning

The app cannot reverse exposure that occurred before import. Files originating from email or cloud drives may already exist with those providers.
