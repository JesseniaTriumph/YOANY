# Model Runtime Specification

## Runtime Goals

- Run locally only
- Have no online path
- Be bounded in scope, time, and memory
- Produce typed proposal output only

## Runtime Rules

- Models must execute only through app-controlled adapters
- Model runtimes may not open network connections
- Model runtimes may not access arbitrary filesystem locations
- Tool calling is prohibited in the manuscript-processing path
- One heavy model operation at a time for MVP unless explicitly re-reviewed

## Inputs

- Authorized segment/page scope only
- Minimal glossary context
- Route metadata where needed

## Outputs

- Structured proposals only
- Explicit uncertainty
- Explicit meaning-change and composition-change flags where applicable

## Operational Bounds

- max characters per request
- max pages per request
- max execution time
- cancellation support
- low-memory failure behavior

## Verification

- Offline execution confirmation
- Runtime no-network observation
- Memory/latency profiling on supported iPads
