# System Architecture

## 1. Architectural style

Native, single-device, local-first iPadOS application with no remote manuscript-processing services.

## 2. Major components

```text
SwiftUI Presentation Layer
        |
Application Workflow Controller
        |
+----------------+----------------+----------------+
|                |                |                |
Vault Service    Import Service   Revision Engine  Export Service
|                |                |                |
Encrypted Store  Safe Parsers     Structured Diff  Auth Gate
        |
On-Device Processing Coordinator
        |
+----------------+----------------+----------------+
|                |                |                |
Rule Engine      Translation      Editing/Review   Semantic QA
                 Model Adapter    Model Adapter
```

## 3. Trust boundaries

### TB-1: Outside app to document picker

Untrusted files may contain malformed structures, active content, misleading extensions, malicious text instructions, oversized resources, or hostile PDF objects/content streams.

### TB-2: Encrypted vault to decrypted working memory

Project content becomes readable only after authentication and only for the minimum operation scope.

### TB-3: Controller to model adapter

The model is untrusted and non-authoritative. It receives bounded text and returns schema-constrained proposals.

### TB-4: App container to external export destination

Decrypted export crosses the privacy boundary and requires exact confirmation.

### TB-5: App lifecycle to operating system

Backgrounding, screenshots, task-switcher previews, backups, keyboards, clipboard, and file-provider destinations may expose content unless constrained.

## 4. Technology baseline

- Swift and SwiftUI
- Structured concurrency and actors
- CryptoKit authenticated encryption
- Keychain-protected key wrapping; Secure Enclave-backed protection where applicable
- Apple Data Protection for app files
- Core ML for custom on-device models
- Apple Natural Language framework for tokenization and language utilities
- PDF parsing and text extraction only through constrained, local, reviewed components
- SQLite/Core Data only if encrypted project fields remain protected; otherwise encrypted package storage
- OSLog with privacy redaction and no manuscript content

## 5. Forbidden architecture elements

- WebView manuscript editor
- Remote API client in the private processing target
- Cloud model fallback
- Remote analytics or crash SDK
- Cloud database
- Shared local HTTP model server
- Arbitrary plugin system
- Arbitrary model download or execution
- App Groups containing manuscript data
- CloudKit/iCloud project container

## 6. Controller responsibilities

The deterministic controller must decide:

- Whether a project is unlocked
- Which project and segments may be read
- Which model role may receive which fields
- Which approved source-target language direction is active
- Maximum input, output, time, memory, and concurrency
- Whether output conforms to schema
- Whether a proposed change affects protected structure
- Whether a proofreading suggestion exceeds allowed composition-preservation boundaries
- Whether user approval is required
- Whether export or deletion confirmation is valid

## 7. Fail-closed rules

- Missing model: disable feature.
- Model initialization failure: preserve project state and stop.
- Invalid output: discard proposal and show non-sensitive error.
- Low storage: stop before mutation.
- Authentication unavailable: keep vault locked.
- Parser uncertainty: quarantine or reject file.
- PDF text extraction uncertainty or missing text layer: quarantine, reject, or require a later OCR-specific design; never silently invent text.
- Destination unavailable: do not create persistent plaintext fallback.
- Any unexpected network dependency: block release.
