# AI System Specification

## Roles

- Proofreading
- Translation
- Review assistance

## Safety Model

- AI is core to the workflow but non-authoritative
- AI may only process controller-selected local text
- AI returns structured proposals only
- AI has no network, tools, or cross-project visibility

## Output Contract

- segment/page references
- proposal text
- reason
- uncertainty
- meaning-change flag
- composition-change flag
