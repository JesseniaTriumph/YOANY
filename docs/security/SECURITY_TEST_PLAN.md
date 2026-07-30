# Security Test Plan

## Test format

Each test records: ID, risk, preconditions, action/attack, expected secure behavior, evidence, result, and release severity.

## Critical tests

| ID | Test | Expected result | Severity if failed |
|---|---|---|---|
| SEC-001 | Run all core workflows in airplane mode | Import, edit, translate, review, save, and encrypted export work locally | Critical |
| SEC-002 | Capture network traffic during manuscript processing | Zero outbound manuscript-processing connections | Critical |
| SEC-003 | Attempt project access before authentication | No decryption or sensitive metadata | Critical |
| SEC-004 | Background app while project is open | Snapshot obscured and project locks | High |
| SEC-005 | Attempt Project A retrieval while Project B active | Access denied; no content leakage | Critical |
| SEC-006 | Inject instructions inside manuscript | No policy change, tool access, or cross-project retrieval | High |
| SEC-007 | Return malformed/hostile model output | Output rejected; no mutation or unsafe rendering | High |
| SEC-008 | Bypass UI and call acceptance directly | Controller requires valid unlocked project and exact revision state | Critical |
| SEC-009 | Replay export confirmation | Rejected | High |
| SEC-010 | Substitute project/revision after confirmation | Rejected | Critical |
| SEC-011 | Search logs for synthetic manuscript marker | Marker absent | Critical |
| SEC-012 | Tamper with model package | Model rejected before loading | High |
| SEC-013 | Import path traversal/archive bomb/malformed DOCX | Rejected or safely quarantined without resource exhaustion | Critical |
| SEC-014 | Delete project and attempt reopen | Project cannot be decrypted; caches/previews absent | High |
| SEC-015 | Simulate local model unavailability | Feature disables; no cloud fallback | Critical |
| SEC-016 | Import malformed or hostile PDF | Rejected or safely quarantined without resource exhaustion or unsafe extraction | Critical |
| SEC-017 | Translate French PDF page by page | Page order preserved; missing or ambiguous extraction flagged; no cloud processing | Critical |
| SEC-018 | Render and review French-to-Arabic translation output | Bidirectional order, punctuation, numerals, and page alignment remain correct and reviewable | Critical |
| SEC-019 | Proofread French source text conservatively | Grammar improves while meaning, composition, and intent remain preserved or are explicitly flagged | Critical |
| SEC-020 | Ingest manuscript content from Apple Notes handoff | Explicit local handoff succeeds without relying on private Notes storage or any network path | High |

## Privacy tests

- Check backup eligibility and exported device backup artifacts.
- Check Spotlight and Siri indexing.
- Check task switcher, notifications, pasteboard, and temporary directories.
- Check that third-party SDK inventory is empty for analytics/ads/remote logging.
- Search final app bundle for remote API hosts and forbidden SDK identifiers.

## Reliability tests

- Low storage before save/export.
- App termination during import, translation, acceptance, export, and deletion.
- Memory pressure during large chapter processing.
- Device rotation, screen lock, and multi-window lifecycle.
- Model timeout/cancellation and resumed workflow.
- Corrupted encrypted archive restore.

## Quality-safety tests

- Numbers and dates preserved.
- Names and glossary terms preserved.
- Negation and modality changes flagged.
- Missing, duplicated, reordered, merged, or split segments flagged.
- Dialogue punctuation and formatting preserved.
- Ambiguous passages flagged rather than asserted confidently.
- PDF page alignment preserved between source and translated review output.
- Arabic bidirectional text, punctuation, and numeral placement preserved in review and export previews.
- French proofreading preserves voice, intent, and sentence composition unless a suggestion is explicitly marked as changing them.

## Evidence requirements

- Automated test output
- Packet/network capture report
- App bundle dependency and host scan
- Screen recordings using synthetic text only
- File-system inspection using synthetic projects
- Model benchmark report
- Signed release checklist
