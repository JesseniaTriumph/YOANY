# Risk Register

| ID | Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|---|
| R-001 | PDF extraction quality is insufficient for reliable translation review | High | High | Restrict MVP to text-layer PDFs, validate text-layer integrity, reject ambiguous files |
| R-002 | Local model quality changes meaning or composition during proofreading | High | High | Conservative proofreading mode, composition validator, human approval |
| R-003 | Supported iPad hardware cannot sustain model latency or memory requirements | High | Medium | Define minimum hardware early, benchmark before model commitment |
| R-004 | Export creates unintended plaintext residue | High | Medium | Temp cleanup, exact confirmation, metadata-only diagnostics |
| R-005 | Third-party dependency introduces network or telemetry behavior | Critical | Medium | Allowlist, scan script, dependency review, runtime inspection |
| R-006 | Right-to-left review support is incorrect for Arabic | High | Medium | Separate RTL validation gate and rendering tests |
| R-007 | OCR pressure expands scope and destabilizes import architecture | High | Medium | Keep OCR explicitly out of MVP until separately designed |
