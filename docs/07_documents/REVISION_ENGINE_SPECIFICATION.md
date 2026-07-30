# Revision Engine Specification

## Purpose

Track every accepted manuscript change without mutating the immutable source snapshot.

## Core Rules

- AI outputs are proposals only.
- User edits are recorded as revision events, not destructive overwrites.
- Accepted revisions must reference prior segment state.
- Rejected revisions must not mutate working state.
- Undo and restore must reconstruct prior accepted states deterministically.

## Required Revision Fields

- `revision_id`
- `project_id`
- `segment_id`
- `prior_hash`
- `new_hash`
- `proposal_kind`
- `meaning_change`
- `composition_change`
- `accepted_by_user`
- `created_at`

## Engine Guarantees

- Source snapshot remains immutable
- Revision lineage is auditable
- Accept/reject/undo/restore are reversible operations
- Revision history cannot cross projects

## Failure Rules

- If revision persistence fails, working state must roll back atomically
- If revision lineage is corrupted, export must block until resolved
