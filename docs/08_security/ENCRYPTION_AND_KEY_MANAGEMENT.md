# Encryption And Key Management

## Current Strategy

- Per-project random data encryption key
- Authenticated encryption for stored payloads
- Wrapped keys protected by Keychain-backed storage in production

## Constraints

- Keys must never be logged
- Decryption occurs only after authorization
- Project deletion removes wrapped key material and encrypted files
