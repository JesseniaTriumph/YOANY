# Domain Model

## Core Aggregates

- `ProjectAggregate`
- `CanonicalDocument`
- `RevisionTimeline`
- `Glossary`
- `AIProposal`

## Invariants

- Source snapshot is immutable
- Segment ordering is stable
- Page ordering is stable
- AI proposals never mutate stored content directly
- Export cannot occur without explicit confirmation state
