# Release Checklist

- Product and security docs are current
- Dependency scan passes
- No-network checks pass
- Vault and authorization tests pass
- Import tests pass
- Proofreading and translation acceptance tests pass
- Export confirmation and cleanup tests pass
- Claims match evidence

## Private tester handoff additions

- Target iPad model and exact iPadOS version recorded
- Deployment target compatibility confirmed (`iPadOS 17.0+`)
- Developer Mode enabled on the tester device
- Personal Team signing path confirmed in Xcode
- Unique bundle identifier chosen for the tester install
- Install/launch smoke test completed on the physical iPad
- Synthetic plain-text, DOCX, and PDF import smoke tests completed
- Proofreading and translation smoke tests completed on device
- Encrypted backup export/restore smoke tests completed on device
- Known unverified release blockers communicated to the tester before handoff
