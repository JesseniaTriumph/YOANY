# Technical Requirements Document

## Platform

- Swift
- SwiftUI
- Structured concurrency
- Local file access through app-private storage and security-scoped imports

## Runtime Requirements

- No network dependency for manuscript path
- Local AI execution only
- Encrypted per-project persistence
- Canonical document model with page-aware structure

## Interfaces

- Import adapters: `TXT`, `DOCX`, `PDF`
- Notes ingestion adapter: explicit local handoff only
- AI adapters: proofreading, translation
- Export adapters: encrypted archive, local `DOCX`/`PDF`
