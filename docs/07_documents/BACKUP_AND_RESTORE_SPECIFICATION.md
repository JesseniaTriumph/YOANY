# Backup And Restore Specification

## Backup Types

- Encrypted archive export
- Local decrypted publishing export

## Restore Scope

Restore applies only to encrypted archive packages, not to decrypted publishing files.

## Archive Requirements

- Project metadata manifest
- Encrypted source snapshot
- Encrypted revision history
- Glossary/style-guide payload
- Version markers
- Integrity digest

## Restore Rules

- Archive integrity must be verified before any project state is accepted
- Restored project must receive a valid authorized local identity
- Corrupted or substituted archives must be rejected
- Restore must not overwrite an existing project silently

## Failure Handling

- Failed restore leaves existing projects untouched
- Temporary decrypted material from restore must be removed after failure
