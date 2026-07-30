# On-Device AI Model Strategy

## 1. Principles

- No model receives network access, filesystem access, tools, or arbitrary code execution.
- Models are replaceable components behind typed adapters.
- Translation, editing, and review are separate roles.
- Deterministic validation runs before and after AI processing.
- Human approval controls manuscript mutation.
- The system fails closed when a required local model is unavailable.

## 2. MVP model roles

### Language identification

Use Apple Natural Language or a compact local classifier.

### Proofreading

Use local dictionaries and deterministic rules first. A small on-device language model may propose higher-level corrections. For French-source proofreading, the default mode must preserve composition, factual meaning, and authorial intent rather than rewrite freely.

### Translation

Use a compact, language-pair-specific Core ML model selected after licensing, quality, memory, latency, and energy testing. The architecture must support routing between any approved supported source-target pair. Initial release scope is French to English. French to Spanish, French to Portuguese, and French to Arabic are follow-on priorities after the same gate process. Arabic support additionally requires bidirectional-text and right-to-left review validation.

### Editing/review

Use Apple’s on-device foundation model where available or a packaged Core ML model. The adapter must reject any provider requiring remote processing.

### Semantic consistency

Use a compact multilingual embedding model and deterministic checks for names, numbers, negation, modal strength, segment count, and formatting.

## 3. Model package manifest

Each approved model must declare:

- Model ID and role
- Version
- Source and provenance
- License status
- Supported iPad models and OS versions
- Supported languages
- Quantization and expected memory
- Cryptographic digest/signature
- Required input/output schema
- Benchmark version and acceptance result
- Network requirement: must be false
- Remote code: must be false

## 4. Runtime limits

- Maximum selected scope
- Maximum tokens/characters per segment batch
- Maximum generated output
- Maximum processing time
- One heavy model operation at a time for MVP
- Cancellation and checkpoint behavior
- Thermal and low-power degradation behavior

## 5. Output schema

Every suggestion must include:

- Segment ID
- Page reference when the source format is page-oriented
- Operation type
- Original text hash/reference
- Proposed replacement or annotation
- Category
- Human-readable reason
- Meaning-change flag
- Composition-change flag
- Uncertainty indicator

Unknown fields are rejected. Output never directly triggers storage mutation.

## 6. Model-selection gates

A model may enter the application only after:

1. License review
2. Provenance and artifact verification
3. Offline execution confirmation
4. Memory/latency testing on target hardware
5. Quality benchmark pass
6. Privacy and logging inspection
7. Prompt-injection and malformed-output testing
8. Rollback package availability
9. For PDF workflows, page-alignment benchmark pass
