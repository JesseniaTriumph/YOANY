# TestFlight Distribution Guide

Last updated: 2026-07-30

This guide covers what is already prepared in the repository versus what still must be done in Apple tooling before a TestFlight-style distribution can succeed.

## Repository state

- Native iPad target builds for iOS Simulator.
- Unsigned iPad archive succeeds with `xcodebuild`.
- The app bundle now contains:
- `PrivacyInfo.xcprivacy`
- compiled launch-screen resources
- wired iPad app icon metadata and asset catalog output
- Privacy/tracking posture remains local-only in source: no analytics, no ads, no remote logging, no cloud manuscript path.

## Remaining manual Apple steps

1. Open `YoanTranslatorApp.xcodeproj` in Xcode.
2. Set the Apple Developer team on the `YoanTranslatorApp` target.
3. Replace `com.openai.YoanTranslatorApp` with the final unique bundle identifier.
4. Confirm version/build numbers for the intended release train.
5. Create the matching app record in App Store Connect.
6. Archive with signing enabled and upload through Xcode Organizer.
7. Complete App Store Connect metadata, export-compliance answers, privacy questionnaire, and TestFlight tester configuration.

## Expected archive command

Unsigned verification command already proven in the repository:

```sh
xcodebuild -project YoanTranslatorApp.xcodeproj \
  -scheme YoanTranslatorApp \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  archive \
  -archivePath /tmp/YoanTranslatorApp.xcarchive
```

Signed upload should be performed from Xcode once team and bundle identifier are set.

## Known non-packaging blockers

- Real iPad install and lifecycle verification
- Airplane-mode and network-capture evidence
- PDF real-sample validation and page-review fidelity
- French proofreading and translation quality validation on target hardware
- Signer rotation/revocation policy for distributable model bundles
- Legal/export-compliance review

## Release decision

- Package readiness for TestFlight-style distribution: `CONDITIONAL`
- Overall product release readiness: `BLOCKED`
