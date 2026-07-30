# Functional Requirements

## Project Lifecycle

- Create, list, lock, unlock, and delete encrypted projects
- Preserve immutable source snapshot
- Maintain revision history

## Import

- Support `TXT`, `DOCX`, and text-layer `PDF`
- Support Apple Notes ingestion through explicit local user handoff paths where the note is provided as text or attached/exported file content
- Validate structure, size, and safety before acceptance
- Preserve stable page and segment mapping

## Proofreading

- Run deterministic checks first
- Produce proposal-only French proofreading suggestions
- Flag meaning change and composition change separately

## Translation

- Support any approved source-target route architecturally
- Prioritize French-to-English for first delivery
- Preserve page review boundaries for PDFs

## Export

- Export encrypted archive for safe backup
- Export local decrypted publishing file only after explicit confirmation
