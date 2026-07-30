# Project Isolation Specification

## Goal

Ensure no project can access, influence, or leak data from another project.

## Isolation Rules

- Every project has a unique opaque `ProjectID`.
- Every project has its own data-encryption key.
- Revision events are project-scoped.
- Glossary and style-guide entries are project-scoped.
- Model contexts are project-scoped and cleared on project switch or lock.
- Export confirmations are bound to a single project and revision context.

## Forbidden Behaviors

- Reusing cached model context across projects
- Resolving project identity from user-editable fields
- Allowing a background task from one project to complete against another
- Accepting a revision event without verifying active authorized project

## Required Controls

- Actor-isolated project session controller
- Explicit project parameter on every repository access
- Context teardown on lock, close, switch, and failure
- Negative tests for cross-project retrieval and revision injection
