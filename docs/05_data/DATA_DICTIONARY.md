# Data Dictionary

## Project

- `project_id`: opaque identifier
- `encrypted_title`: encrypted user-visible name
- `state`: locked, unlocked, deleted

## DocumentPage

- `page_id`: opaque identifier
- `page_index`: zero-based page order
- `source_range`: mapping back to source import representation

## DocumentSegment

- `segment_id`: opaque identifier
- `page_id`: owning page
- `kind`: paragraph, heading, dialogue, footnote, scene break
- `text`: protected content
- `order_index`: stable position

## RevisionEvent

- `revision_id`: opaque identifier
- `segment_id`: affected segment
- `proposal_kind`: proofreading, translation, user-edit
- `meaning_change`: boolean
- `composition_change`: boolean
