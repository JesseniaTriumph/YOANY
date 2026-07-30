# Decision Log

| ID | Decision | Current position | Status | Security impact |
|---|---|---|---|---|
| D-001 | Platform | Native iPadOS app built with Swift and SwiftUI | Decided | Eliminates browser cookies and remote web runtime |
| D-002 | Processing | On-device only; fail closed if local capability is unavailable | Decided | Prevents silent cloud transmission |
| D-003 | Storage | App-private encrypted project vault; no cloud project storage | Decided | Reduces cross-service exposure |
| D-004 | AI authority | AI proposes and reviews; user controls acceptance; proofreading must improve grammar and correctness without silently changing composition, meaning, or authorial intent | Decided | Prevents excessive agency and constrains source-language rewriting risk |
| D-005 | Networking | Private editing target contains no manuscript networking code | Decided | Major privacy boundary |
| D-006 | Initial file formats | DOCX, plain text, and PDF manuscript import are required; PDF translation must preserve page-level review boundaries; EPUB remains later | Decided | Expands parser attack surface and requires stricter PDF quarantine and extraction controls |
| D-013 | Apple Notes support | Support Apple Notes as a local ingestion source through explicit user handoff, exported/attached files, shared copies, or note text extraction where platform APIs allow; do not depend on or reverse-engineer Notes private storage format | Decided | Avoids unstable undocumented storage coupling while preserving local workflow support |
| D-007 | Translation languages | The architecture should support translation between any approved supported language pair; first-release priority is French to English, with French source proofreading/review also required; French to Spanish, French to Portuguese, and French to Arabic are planned next; other languages later | Decided | Determines model packaging, direction-pair routing, bidirectional-text safety requirements, benchmarks, glossary strategy, and rollout gates |
| D-008 | Minimum iPad hardware | Define after model performance prototype | Open | Affects compatibility and local inference feasibility |
| D-009 | Distribution | App Store, private distribution, or local development deployment | Open | Affects signing, updates, model packaging, privacy disclosures |
| D-010 | Backups | Encrypted manual archive only in initial release | Proposed | Avoids automatic cloud leakage |
| D-011 | Export policy | Encrypted archive by default; decrypted export requires Face ID/passcode | Proposed | High-impact disclosure control |
| D-012 | Apple on-device foundation model | Optional editing/review accelerator, never required and never cloud-backed | Proposed | Availability and OS-version dependency |
