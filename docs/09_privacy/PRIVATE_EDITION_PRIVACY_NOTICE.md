# Private Edition Privacy Notice

Last updated: 2026-07-30

## What this app is designed to do

This private edition is designed to process manuscripts locally on the iPad. The intended product architecture does not rely on cloud manuscript processing, cloud sync, analytics, advertising, remote logging, or third-party tracking SDKs.

## Data the app stores locally

- Encrypted project data for imported manuscripts and accepted revisions
- Immutable source snapshots for imported documents
- Local glossary and review settings associated with a project
- Optional encrypted backup archives created by explicit user action
- Metadata-only diagnostic and audit records that must not contain manuscript text

## Data the app is not intended to collect or transmit

- Manuscript text for cloud processing
- Analytics events
- Advertising identifiers
- Remote crash uploads
- Remote feature-flag or tracking data

## Local exports and backups

- Plaintext export requires explicit user action and is treated as a deliberate local handoff outside the encrypted vault.
- Encrypted archive export is optional and user-initiated.
- Export destinations and preview/indexing behavior still require on-device validation before release claims can be finalized.

## Local AI behavior

- AI-generated edits and translations are proposals, not automatic source mutations.
- The controller is intended to send only the minimum authorized passage and glossary context to a local model runtime.
- Real model quality, legal review, and device privacy evidence remain release gates.

## Current verification status

- Repository tests and simulator builds have been run.
- Real-device privacy behavior, no-network capture evidence, and Files/export behavior still require retained release evidence before shipment.

## Contact with external services

The intended private-edition design does not include manuscript-processing network services. Release remains blocked until target-device evidence confirms the shipped build matches that design.
