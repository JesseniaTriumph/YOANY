# Document Import Specification

## Supported Formats

- `UTF-8 text`
- `DOCX`
- text-layer `PDF`
- Apple Notes as a local ingestion source when content is handed off explicitly as note text or attached/exported files

## Import Rules

- Validate type and size before parsing
- Parse in a constrained local component
- Reject active or unsupported content
- Produce canonical page/segment model
- Remove temporary plaintext after completion
- Do not depend on undocumented Apple Notes private storage formats as a parser contract
- Treat Notes support as an ingestion boundary, not as a canonical storage format

## PDF Rule

If page mapping or text-layer confidence is insufficient, reject or quarantine the file.
