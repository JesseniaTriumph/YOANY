# Personal Team Sideload Guide

Last updated: 2026-08-01
Distribution mode: direct Xcode install to a tester-owned iPad using a free Apple ID Personal Team

## Purpose

Use this path when:

- the tester only needs a private build
- App Store / TestFlight distribution is not being used yet
- the app must stay native and local-only

This is a tester-install path, not a release path.

## What this path does and does not provide

What it provides:

- direct installation from Xcode to a connected iPad
- no App Store listing
- no TestFlight requirement
- no paid Apple Developer membership requirement

What it does not provide:

- durable long-term provisioning
- public or semi-public install links
- App Store Connect distribution
- evidence that the product is release-ready

Personal Team provisioning is expected to expire and require reinstall/reprovisioning.

## Preconditions

- Mac with Xcode installed
- free Apple ID available in Xcode
- physical iPad available for direct install
- iPad has enough free space for the app, documents, and temporary test artifacts
- USB connection or trusted local connection between Mac and iPad

## Current build footprint

Current verified repository evidence:

- unsigned archived app bundle size: about `1.5 MB`
- unsigned archive size: about `8.1 MB`

This does not include future user documents, exported backups, or Apple-managed on-device language assets.

## Required iPad checks before first install

1. Confirm the iPad model and exact iPadOS version.
2. Confirm at least `iPadOS 17.0` because the current deployment target is `17.0`.
3. Confirm enough free space remains after accounting for the tester's own files.
4. Confirm Developer Mode can be enabled on the device.
5. Confirm the tester accepts that Personal Team installs may need to be reinstalled later.

## Xcode install steps

1. Open `YoanTranslatorApp.xcodeproj` in Xcode.
2. Connect the iPad to the Mac and trust the computer if prompted.
3. In Xcode, select the `YoanTranslatorApp` target.
4. Open `Signing & Capabilities`.
5. Select the free Apple ID `Personal Team`.
6. Replace `com.openai.YoanTranslatorApp` with a unique bundle identifier you control.
7. Select the connected iPad as the run destination.
8. Build and run from Xcode.
9. If the iPad prompts for Developer Mode, enable it and restart the device if required.
10. Re-run from Xcode after Developer Mode is enabled.

## First-run tester checklist

After install, verify at minimum:

1. App launches successfully.
2. Project creation works.
3. Unlock and relock behavior works.
4. Plain-text import works.
5. DOCX import works on a synthetic sample.
6. PDF import works on a text-layer synthetic sample.
7. French proofreading flow produces staged proposals.
8. Translation flow produces staged proposals for at least one supported route.
9. Accept/reject review actions work.
10. Encrypted backup export works.
11. Restore-from-backup works with a synthetic project.
12. Delete confirmation works and the project cannot be reopened.

## Known open evidence gaps

This path does not close these release blockers:

- real-device network isolation capture
- real-device privacy/snapshot evidence
- real DOCX formatting fidelity validation
- deeper PDF confidence and page-review validation
- on-device proofreading quality validation
- on-device translation quality validation
- right-to-left review safety validation
- cross-device recovery validation

## Handoff decision

- Xcode Personal Team tester handoff: `CONDITIONAL`
- Overall product release readiness: `BLOCKED`
