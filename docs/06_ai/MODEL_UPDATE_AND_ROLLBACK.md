# Model Update And Rollback

## Purpose

Control how local model assets evolve without weakening privacy or manuscript integrity.

## Rules

- No runtime download dependency for core workflows
- New model packages require provenance and license review
- Every model package requires digest verification
- Every update requires regression evaluation before activation
- Prior approved model packages must remain available for rollback until replacement is validated

## Update Process

1. Acquire model package through approved offline or bundled path
2. Verify signature/digest/provenance
3. Run benchmark suite
4. Run privacy and no-network checks
5. Activate only after explicit approval

## Rollback Triggers

- Quality regression
- Performance regression
- Unexpected network activity
- Output-schema instability
- Privacy or security failure
