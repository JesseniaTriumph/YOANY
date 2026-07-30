# State Transition Diagrams

## Project Lifecycle

`Absent -> CreatedLocked -> Unlocking -> Unlocked -> Locked -> Deleted`

Rules:

- `CreatedLocked` is the default post-create state.
- `Unlocking` may transition only to `Unlocked` or back to `Locked`.
- Backgrounding or authentication expiration forces `Unlocked -> Locked`.
- `Deleted` is terminal.

## Import Lifecycle

`Idle -> FileSelected -> Quarantine -> Validating -> Parsing -> Canonicalized -> SourcePersisted -> Complete`

Failure edges:

- `Quarantine -> Rejected`
- `Validating -> Rejected`
- `Parsing -> Rejected`
- `SourcePersisted -> FailedAtomicRollback`

Rules:

- No partially imported project may become visible as a valid source snapshot.
- Temporary plaintext must be removed on every non-terminal failure edge.

## Proofreading Lifecycle

`Idle -> ScopeSelected -> DeterministicChecks -> ModelProposal -> Validation -> Review -> AcceptedOrRejected -> Idle`

Failure edges:

- `ModelProposal -> FailedUnavailable`
- `Validation -> RejectedProposal`
- `Review -> Cancelled`

Rules:

- `AcceptedOrRejected` creates revision events only for accepted proposals.
- Composition-changing proposals must be explicitly flagged before `Review`.

## Translation Lifecycle

`Idle -> RouteSelected -> ScopeMapped -> ModelProposal -> Validation -> PageReview -> AcceptedOrRejected -> Idle`

Failure edges:

- `ScopeMapped -> FailedUnsupportedRoute`
- `ModelProposal -> FailedUnavailable`
- `Validation -> RejectedProposal`

Rules:

- PDF page alignment must survive until `PageReview`.
- No accepted translation may bypass validation.

## Export Lifecycle

`Idle -> ExportRequested -> Reauthenticate -> Confirming -> Rendering -> LocalHandoff -> Cleanup -> Complete`

Failure edges:

- `Reauthenticate -> Denied`
- `Confirming -> Cancelled`
- `Rendering -> Failed`
- `LocalHandoff -> Failed`
- `Cleanup -> CleanupWarning`

Rules:

- Decrypted publishing export cannot start rendering before successful reauthentication and exact confirmation.
- Cleanup warnings are security-significant events.
