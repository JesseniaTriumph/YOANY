# Offline Operation Architecture

## Rule

The manuscript-processing path has no online path whatsoever.

## Consequences

- No remote service dependencies
- No runtime downloads
- No cloud-backed model route
- No network-based policy or feature controls

## Verification

- Static dependency scan
- Runtime network capture
- Airplane-mode workflow tests
