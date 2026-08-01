# Tester Device Acceptance Checklist

Last updated: 2026-08-01
Audience: the person running the first private iPad trial

## Device readiness

- iPad model recorded
- exact iPadOS version recorded
- `iPadOS 17.0` or newer confirmed
- free storage recorded before install
- Developer Mode enabled
- device passcode configured
- local Apple ID Personal Team available in Xcode

## Install readiness

- unique bundle identifier chosen
- app builds from Xcode
- app installs on the target iPad
- app launches without immediate crash

## Privacy and security smoke checks

- app opens with no account/login requirement
- no analytics or tracking prompts appear
- project remains inaccessible until unlocked
- relocking works after manual lock
- screen obscuring behavior is observed during backgrounding

## Functional smoke checks

- create a project
- import plain text
- import a DOCX sample
- import a PDF sample with a text layer
- run French proofreading
- run translation for at least one route
- accept a single proposal
- accept all proposals
- clear proposals
- export an encrypted backup
- restore that backup
- delete the test project

## Quality observations to record

- proofreading suggestions that feel too aggressive
- translation output that drops names, dates, numbers, or negation
- page order issues in imported PDF review
- Arabic or right-to-left rendering problems if tested
- freezes, memory pressure, or thermal problems

## Evidence to retain

- screenshots of successful install
- screenshots of key workflows
- notes on any failures or warnings
- exact device model and iPadOS version
- free storage before and after install

## Result

- `READY FOR PRIVATE TEST`
- `CONDITIONAL PRIVATE TEST`
- `BLOCKED`
