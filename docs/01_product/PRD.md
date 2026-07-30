# Product Requirements Document

## Product

Private on-device manuscript editor, proofreader, translator, and review system for iPad.

## Problem

The user needs to work on private manuscripts without exposing them to cloud AI providers, analytics vendors, or external services, while still using local AI to improve grammar and produce translation drafts.

## Core Product Promise

The app keeps manuscript processing local, encrypted, and review-driven. Outside services do not get access through the intended architecture.

## MVP Scope

- Import `TXT`, `DOCX`, and text-layer `PDF`
- Import from Apple Notes through explicit local handoff paths such as shared text or attached/exported files
- Create encrypted local projects
- Proofread French conservatively
- Translate French to English
- Review proposals page by page for PDFs
- Accept/reject/undo changes
- Export encrypted archive or deliberate local publishing output

## Out Of Scope

- Cloud processing
- Sync/collaboration
- OCR
- Automatic publishing
- Background processing while locked

## User Success

- The user can safely import a manuscript
- The user can improve French grammar without losing intent
- The user can review French-to-English translation locally
- The user can export a final local document intentionally
