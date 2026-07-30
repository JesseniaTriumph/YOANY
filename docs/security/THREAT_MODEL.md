# Threat Model

## Protected assets

- Manuscript originals and revisions
- Translation and editing outputs
- Glossary, style guide, and character data
- Project encryption keys
- Model packages and evaluation baselines
- Application integrity and privacy promise

## Threat actors and failure sources

- Malicious document author or corrupted file
- Another application on the device
- Third-party keyboard or file provider
- Person with device access
- Compromised/jailbroken device
- Malicious or compromised dependency/model package
- The AI producing incorrect, manipulative, or structure-breaking output
- User accidentally exporting to an unsafe destination

## AI Threat Matrix

| Category | Applicability | Product-specific scenario | Primary controls | Required evidence | Residual risk |
|---|---|---|---|---|---|
| AI-01 Prompt injection | APPLICABLE | Manuscript text tells model to ignore rules or reveal other content | Treat text as data; no tools; bounded context; controller authority | Hostile-document tests | Model may still produce bad suggestions |
| AI-02 Insecure output handling | APPLICABLE | Malformed output changes structure or is rendered unsafely | Typed schema; validation; proposal-only mutation | Invalid-output tests | Subtle semantic errors remain |
| AI-03 Data poisoning | PARTIALLY APPLICABLE | Poisoned model package or glossary changes behavior | Signed models; provenance; versioning; glossary audit | Tampered-package and glossary tests | Upstream training data cannot be fully verified |
| AI-04 Model denial of service | APPLICABLE | Huge file/context exhausts memory or freezes device | Size, context, concurrency, timeout, cancellation limits | Stress tests | Old devices may remain slow |
| AI-05 Supply chain | APPLICABLE | Compromised model/dependency executes or leaks | Pinning, signature, digest, license and provenance review | Build and artifact verification | Vendor/upstream compromise risk |
| AI-06 Sensitive disclosure | CRITICAL | Text leaks through network, logs, cross-project context, export | No network; encryption; isolation; minimal logs; export gate | Network, logging, cross-project tests | Compromised OS can still observe plaintext |
| AI-07 Insecure tools/plugins | NOT CURRENTLY APPLICABLE | No model tools or plugins in MVP | Prohibit tools/plugins | Architecture inspection | Must reassess if added |
| AI-08 Excessive agency | APPLICABLE | Model automatically replaces or exports manuscript | Proposal-only; human approval; deterministic controller | Direct-call bypass tests | User may over-approve changes |
| AI-09 Overreliance | APPLICABLE | User assumes translation or French proofreading is publication-ready despite subtle intent/composition drift | Comparison, uncertainty, QA flags, immutable source | Quality and ambiguity tests | Human language judgment remains necessary |
| AI-10 Model/knowledge theft | APPLICABLE | Unauthorized access to project or packaged model | Sandbox, encryption, key protection, export restrictions | File-access and backup tests | Device compromise remains |

## Traditional high-risk threats

### T-01 Malicious archive/document

Attack: decompression bomb, path traversal, malformed XML, external relationship, macro, embedded executable.

Control: strict format parser, limits, quarantine, allowlisted elements, safe failure.

### T-06 Malicious or ambiguous PDF

Attack: malformed cross-reference tables, hostile object graphs, embedded actions, oversized streams, deceptive page text order, missing text layer, or image-only scans misrepresented as extractable text.

Control: constrained local PDF parser, object/page/resource limits, embedded-action rejection, text-layer validation, page-map integrity checks, explicit fail-closed behavior when extraction confidence is insufficient.

### T-07 Bidirectional-text or right-to-left rendering failure

Attack/failure: Arabic output renders with incorrect bidirectional ordering, punctuation placement, numeral association, or page-review alignment, causing silent meaning changes or unsafe user approval.

Control: explicit bidirectional-text tests, page-review rendering validation, approved font/layout strategy, numeral and punctuation preservation checks, and right-to-left comparison review before release.

### T-08 Source proofreading overreach

Attack/failure: French proofreading suggestions silently alter sentence composition, narrative voice, factual meaning, or authorial intent while appearing to be mere grammar fixes.

Control: composition-preservation validator, separate meaning-change and composition-change flags, conservative proofreading mode, human review of every suggestion, and benchmark cases for voice/intent preservation.

### T-09 Undocumented Apple Notes format coupling

Attack/failure: implementation relies on private or unstable Notes storage structures, breaking import reliability or expanding privacy risk across OS changes.

Control: support Notes only through explicit local handoff, exported/attached files, or note text intake; avoid reverse-engineering Notes private database/storage formats as a product dependency.

### T-02 Cross-project leakage

Attack: stale model context, cache key error, incorrect project identifier.

Control: actor-isolated project session, explicit project-scoped repository, cache invalidation, negative tests.

### T-03 Export disclosure

Attack: accidental plaintext export to cloud provider or wrong file.

Control: exact confirmation, reauthentication, warnings, encrypted default.

### T-04 Backup/indexing exposure

Attack: OS backup, Spotlight, previews, notifications, clipboard, or shared container exposes text.

Control: backup policy, indexing exclusions, protected files, obscured snapshots, internal clipboard.

### T-05 Key loss or corruption

Attack/failure: key inaccessible after update or deletion race.

Control: versioned key wrapping, migration tests, encrypted archive recovery, atomic operations.

## Security lifecycle mapping

- MAP: architecture, assets, data flows, roles, import/export boundaries.
- ATTACK: malicious file, prompt injection, leakage, bypass, stress, tampered model tests.
- HARDEN: deterministic controller, encryption, schemas, limits, safe parsers, confirmation tokens.
- MONITOR: local metadata-only security events and integrity state.
- RESPOND: lock projects, disable model role, reject package, restore encrypted archive, release rollback.
