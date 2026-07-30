# Project Agent Instructions

## Mandatory workflow

Before every substantial task:

1. Read this file and all files under `docs/security/`.
2. Compare the requested work with the current product profile, architecture, threat model, and security status.
3. Assign Security Review Level 0, 1, or 2.
4. Map affected assets, trust boundaries, data flows, permissions, AI authority, and high-impact actions.
5. Implement deterministic controls alongside the feature.
6. Add positive, negative, adversarial, privacy, and failure tests as applicable.
7. Update `SECURITY_CHANGELOG.md` and `SECURITY_STATUS.md`.
8. Issue READY, CONDITIONAL, or BLOCKED based on evidence.

## Automatic Level 2 triggers

Any new or materially changed AI model, document format, file import, export, project sharing, cloud function, networking capability, model download, user role, biometric flow, encryption scheme, storage destination, analytics capability, crash reporting, external integration, synchronization, or high-impact action triggers Level 2.

## Non-negotiable rules

- Native iPadOS application only. No remotely hosted editor or cloud processing path.
- No manuscript-processing network code.
- No cloud fallback when an on-device model is unavailable.
- No analytics, advertising, remote logging, remote feature flags, or third-party tracking SDKs.
- No iCloud/CloudKit project synchronization in the private edition.
- No AI access to the filesystem, other apps, network, shell, contacts, photos, email, calendar, or unrelated projects.
- The controller supplies only the minimum authorized passage and glossary context to a model.
- Uploaded documents and model output are untrusted.
- Prompts and model refusals do not enforce security.
- Original manuscript data is immutable after import except through explicit creation of a new source version.
- All accepted changes must be traceable and reversible.
- All decrypted exports require explicit authentication and destination warning.
- Security claims require implementation and test evidence.

## Required task report

Every major task must report:

- Security review level
- Trigger
- Affected trust boundaries
- Controls implemented
- Tests added or rerun
- Exact results
- Documentation updated
- Unverified items
- Release decision
