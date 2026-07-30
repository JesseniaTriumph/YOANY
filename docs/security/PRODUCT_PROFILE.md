# Product Profile

Last reviewed: 2026-07-28
Review level: Level 2
Evidence state: Pre-implementation design

| Field | Current profile | Evidence status |
|---|---|---|
| Product | Private on-device iPad manuscript editing and translation app | DOCUMENTED BUT NOT VERIFIED |
| Users | One manuscript owner on one iPad for MVP | INFERRED; confirm before build |
| Primary data | Manuscripts, revisions, translations, glossary, style/character data | DOCUMENTED BUT NOT VERIFIED |
| Sensitivity | Highly sensitive intellectual property and private writing | INFERRED |
| AI capabilities | Local proofreading, translation, editing, comparison, review, including French-source proofreading and page-by-page PDF manuscript translation review | DOCUMENTED BUT NOT VERIFIED |
| AI authority | Proposal only; no autonomous mutation, export, sharing, or deletion | DOCUMENTED BUT NOT VERIFIED |
| Integrations | None in private edition | DOCUMENTED BUT NOT VERIFIED |
| Networking | No manuscript-processing networking | DOCUMENTED BUT NOT VERIFIED |
| Storage | App-private encrypted local vault | DOCUMENTED BUT NOT VERIFIED |
| Accounts | None for MVP | INFERRED |
| Payments | None for MVP | UNKNOWN |
| Deployment | Native iPadOS | DOCUMENTED BUT NOT VERIFIED |
| Compliance | Privacy and consumer-protection obligations potentially relevant; legal review needed before claims | INSUFFICIENT INFORMATION |

## Risk classification

Overall risk: HIGH

Primary risk domains:

- Confidential intellectual property
- Local device privacy
- Malicious document parsing, including PDF parsing and extraction
- AI sensitive-information disclosure
- Translation/editing overreliance
- Model and software supply chain
- Export and backup leakage

## Highest-impact actions

- Decrypt project
- Import untrusted document
- Accept large-scale edits
- Export decrypted manuscript
- Delete project/key
- Install or update model package

## Assumptions requiring confirmation

- Initial user is an adult device owner.
- No collaboration or account system is required.
- The friend can use a supported modern iPad.
- Initial release translation direction is French to English.
- French to Spanish, French to Portuguese, and French to Arabic are the next planned language pairs.
- Distribution method is not yet selected.
