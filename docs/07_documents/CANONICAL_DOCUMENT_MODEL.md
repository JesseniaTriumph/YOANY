# Canonical Document Model

## Purpose

Provide one internal representation across `TXT`, `DOCX`, and `PDF`.

Apple Notes is treated as an input source that must be converted into this canonical model through explicit local handoff.

## Required Elements

- document metadata
- pages
- segments
- formatting hints
- stable ordering
- source mapping
- validation warnings

## Segment Kinds

- paragraph
- heading
- dialogue
- scene break
- footnote
- unknown-preserved block
