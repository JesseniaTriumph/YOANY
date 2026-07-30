# Security, Privacy, Safety, and Reliability Requirements

## 1. Default-deny posture

The system must deny project access, model processing, export, deletion, and model installation unless all required deterministic checks succeed.

## 2. Authentication and project unlock

- Project decryption must require LocalAuthentication using device owner credentials.
- Authentication result must be bound to a short-lived unlock session.
- App backgrounding, inactivity, device lock, or authentication invalidation must lock the project.
- Biometric failure must not reveal project metadata beyond what is necessary.

## 3. Encryption and keys

- Every project must have a unique random data-encryption key.
- Manuscript content, revisions, glossary, suggestions, and titles must be encrypted using authenticated encryption.
- Project keys must be wrapped by a Keychain-protected key.
- The app must never log keys or plaintext content.
- Decryption must occur only after authorization and only for required data.

## 4. Network isolation

- Core editing and AI targets must not contain remote manuscript API clients.
- The manuscript-processing path must have no online path whatsoever, even when network connectivity is available on the device.
- No cloud model fallback is permitted.
- No analytics, advertising, remote logs, remote feature flags, or cloud database SDKs.
- A test must prove core workflows work in airplane mode.
- A network-capture test must show zero manuscript-processing outbound traffic.

## 5. File import

- Validate signature, format, size, entry count, decompression ratio, and supported structure.
- Reject or strip macros, scripts, active content, external relationships, remote templates, embedded executables, and unsupported objects.
- Parse in a constrained component and fail safely.
- Treat document text as untrusted data, never policy.
- Remove temporary plaintext after import.
- For PDFs, validate object structure, page count, stream/resource limits, encryption status, and whether a trusted text layer exists.
- For scanned or image-only PDFs, fail closed unless and until an OCR-specific design is approved and implemented.

## 6. AI boundary

- Models may receive only controller-selected project segments and necessary glossary context.
- Models must have no tools, filesystem, network, shell, or cross-project access.
- All output must conform to an explicit schema and be validated.
- Model output must never directly mutate, export, delete, or publish content.
- User approval is required for substantive edits.
- The AI must not approve its own work.
- Proofreading mode must flag meaning change and composition change separately, and the default French proofreading mode must reject or down-rank suggestions that exceed approved composition-preservation limits.

## 7. Project isolation

- Every data access must include the active project identity established by trusted controller state.
- Model sessions and caches must be cleared between projects.
- Cross-project retrieval is prohibited.
- Tests must attempt to extract one project while another is active.

## 8. Export and deletion

- Decrypted export requires reauthentication and exact-action confirmation.
- Confirmation must bind project, revision, format, destination class, and expiration.
- Encrypted export is the default backup method.
- Decrypted publishing export is allowed only as a deliberate local user action and must not trigger any upload, sync, or publication behavior by the app.
- Project deletion requires reauthentication and exact-project confirmation.
- Delete must remove project key references, encrypted files, caches, previews, and temporary artifacts.

## 9. Logging and privacy

- Logs may contain only minimal operational metadata.
- No manuscript text, prompt text, model output, project title, external filename, full path, key, or credential.
- App-switcher previews must be obscured.
- Notifications must contain no manuscript content.
- Spotlight, Siri suggestions, shared app groups, and cloud containers must not expose project data.

## 10. Supply chain

- Dependencies and models must be inventoried and version-pinned.
- Model files must have verified provenance, license, digest, and signature.
- Arbitrary remote code and arbitrary model installation are prohibited.
- Updates require regression, privacy, security, and quality evaluation.

## 11. Reliability

- Operations must be cancellable where feasible.
- Partial failures must not corrupt the immutable source or accepted revision history.
- Low storage, memory pressure, interruption, and unavailable models must produce safe recovery.
- State-changing operations must be atomic or recoverable.
- Page-by-page translation review for PDFs must preserve page ordering and make omissions, merges, splits, and uncertain extraction visible.

## 12. Release blockers

Release is BLOCKED if:

- Any manuscript-processing path transmits data remotely.
- Project encryption or unlock boundary is absent or untested.
- Cross-project leakage is possible or untested.
- Model output can directly overwrite content.
- Export or deletion confirmation can be bypassed or replayed.
- Malicious file handling is untested.
- Logs or previews expose manuscript content.
- A critical/high AI threat lacks deterministic controls and adversarial tests.
- Model provenance or licensing is unresolved.
