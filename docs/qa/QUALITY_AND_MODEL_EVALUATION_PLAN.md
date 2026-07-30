# Quality and Model Evaluation Plan

## 1. Purpose

Security alone does not make the product safe. Editing and translation errors can damage meaning, voice, continuity, and publication quality. Every model version must pass product-specific evaluation.

## 2. Evaluation corpus

Use synthetic or explicitly authorized text only during development. Include:

- Narrative prose
- Dialogue
- First- and third-person voice
- Names and invented words
- Numbers, dates, units, and money
- Negation and modal verbs
- Idioms and culturally specific references
- Long-range character and terminology consistency
- Deliberate grammatical irregularity and dialect
- Formatting, scene breaks, italics, headings, and footnotes where supported
- PDF page breaks and page-boundary edge cases
- Bidirectional and right-to-left script cases, including Arabic punctuation and numeral placement
- Hostile prompt-like text embedded in prose
- French passages where grammar can be improved without changing syntax rhythm, voice, or intent

## 3. Proofreading metrics

- Precision: percentage of suggestions that are valid
- Recall for defined mechanical error set
- Meaning-preservation failure rate
- Composition-preservation failure rate
- Voice/style alteration rate
- False-positive rate on names and intentional language
- Structured-output validity rate

## 4. Translation metrics

- Human adequacy
- Human fluency
- Terminology consistency
- Name/number/date preservation
- Negation and modality preservation
- Omission/addition rate
- Segment alignment integrity
- Formatting preservation
- Long-document consistency
- PDF page-alignment preservation
- Bidirectional-text rendering and review correctness for Arabic

Automated semantic scores may support evaluation but never replace human review.

## 5. Device metrics

- Peak memory
- Median and p95 latency
- Thermal impact
- Battery usage
- Cancellation responsiveness
- Failure behavior under memory pressure
- Maximum safe chapter/selection size

## 6. Release thresholds

Thresholds must be set after baseline testing. At minimum:

- Zero silent segment loss in the test corpus
- Zero unflagged number/name/negation critical changes in release-blocking tests
- 100% schema-valid production outputs or safe rejection
- No network dependency
- Human approval required for all substantive changes
- Zero silent page loss or page reorder in PDF translation review tests
- Zero unflagged French proofreading changes that alter meaning or composition in release-blocking tests

## 7. Model-change policy

Any model, quantization, tokenizer, prompt template, context strategy, or framework change requires:

- Level 2 review if behavior or trust boundary materially changes
- Full regression benchmark
- Privacy/network test
- Artifact integrity verification
- Rollback plan
- Updated model card and security changelog
