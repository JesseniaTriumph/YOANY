# ERD

## Entities

- `Project`
- `SourceSnapshot`
- `DocumentPage`
- `DocumentSegment`
- `RevisionEvent`
- `GlossaryEntry`
- `AuditEvent`
- `ModelProposal`
- `ExportRecord`

## Relationships

- `Project 1 -> 1 SourceSnapshot`
- `Project 1 -> many DocumentPage`
- `DocumentPage 1 -> many DocumentSegment`
- `Project 1 -> many RevisionEvent`
- `Project 1 -> many GlossaryEntry`
- `Project 1 -> many AuditEvent`
- `RevisionEvent many -> 1 DocumentSegment`
- `ModelProposal many -> 1 DocumentSegment`
