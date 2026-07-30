# Assumptions And Constraints

## Assumptions

- One primary local device owner uses the app on a supported iPad.
- Manuscripts are highly sensitive intellectual property.
- Internet access may exist on the device, but the manuscript path must never use it.
- Initial source language priority is French.
- Initial delivery priority is French proofreading and French-to-English translation.

## Hard Constraints

- Native `iPadOS` app only.
- No online manuscript path whatsoever.
- No cloud model fallback, sync, or remote telemetry.
- Only local approved model assets may be used.
- `TXT`, `DOCX`, and text-layer `PDF` are in scope.
- OCR for scanned/image-only PDFs is out of scope until separately approved.
- Encrypted internal vault is the default storage state.
- Decrypted publishing export is explicit, local, and user-approved only.

## Design Consequences

- Import, review, AI, and export workflows must all be offline-complete.
- Canonical document representation must preserve page and segment mapping.
- AI outputs must remain proposals until accepted by the user.
- Security validation is part of feature completion, not a later phase.
