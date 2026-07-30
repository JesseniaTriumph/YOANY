# User Workflows

## Workflow 1: First launch

1. User sees a plain-language privacy statement.
2. App confirms it does not transmit manuscript content.
3. User enables Face ID/passcode project unlock.
4. App verifies required local capabilities.
5. App does not request network, contacts, photos, microphone, camera, or location permissions.

## Workflow 2: Create and import project

1. User creates a project with a local display name.
2. App creates an opaque internal project ID and unique project key.
3. User selects a supported file through the document picker.
4. App accesses only the selected security-scoped file.
5. Importer validates file signature, size, internal structure, and embedded content.
6. Parser produces a safe internal representation.
7. Original source snapshot is encrypted and marked immutable.
8. Temporary copies are removed.

## Workflow 3: Proofread

1. User chooses a chapter or selection.
2. Controller retrieves only authorized segments.
3. Deterministic checks run first.
4. On-device model may generate structured suggestions.
5. For French-source review, suggestions must preserve composition and intent unless the user explicitly chooses a deeper rewrite workflow later.
6. User accepts, rejects, or edits each suggestion.
7. Accepted changes become revision events.

## Workflow 4: Translate

1. User chooses source language, target language, and scope.
2. Controller verifies an approved local model exists.
3. Text is segmented with stable IDs; for PDFs, page boundaries are preserved for review.
4. Only required glossary terms and nearby context are supplied.
5. Translation output is validated for structure, numbers, names, page alignment, and missing segments.
6. Low-confidence or conflicting segments are flagged.
7. User reviews and approves page by page.
8. The initial release path prioritizes French to English, but the architecture must support later approved pairings without changing core safety controls.

## Workflow 5: Close/background

1. App obscures the task-switcher preview.
2. Active project locks.
3. Plaintext buffers and model session state are released where practical.
4. No background upload, sync, analytics, or remote crash report occurs.

## Workflow 6: Export

### Encrypted archive

1. User authenticates.
2. App creates an encrypted archive containing project data and manifest.
3. User selects destination.
4. App logs metadata-only export event.

### Decrypted final document

1. App explains that the exported copy will no longer be protected by the vault.
2. User authenticates.
3. App displays the exact project, revision, format, and destination.
4. User confirms.
5. Export is generated locally.
6. Temporary plaintext is removed after handoff.

## Workflow 7: Delete

1. User selects project deletion.
2. App displays scope and irreversibility.
3. User reauthenticates and confirms exact project.
4. App destroys the project key and removes project records, caches, previews, and temporary data.
5. App records metadata-only deletion completion.
