# Publication gates for 1.0.0

## Automated engineering gates

- [ ] `bash tool/release_readiness.sh candidate`
- [ ] exact-head strict CI is green
- [ ] arm64 and universal APK signatures verified
- [ ] AAB signature verified
- [ ] arm64 APK ≤ 22 MiB and universal APK ≤ 61 MiB
- [ ] APK permission inventory contains no forbidden permission
- [ ] privacy/data-safety statements match the final dependency and permission inventories
- [ ] no default/demo launcher or store artwork remains

## Maintainer-owned gates

- [ ] permanent upload keystore generated and backed up twice in encrypted independent locations
- [ ] certificate SHA-256 fingerprint recorded
- [ ] GitHub signing secrets configured
- [ ] legal publisher name supplied
- [ ] support/privacy email verified
- [ ] stable public HTTPS privacy-policy URL published
- [ ] Google Play/Cafe Bazaar/Myket developer accounts verified as applicable
- [ ] final icon, feature graphic, and screenshots approved
- [ ] exact signed arm64 candidate installed on named devices
- [ ] cold/warm startup, first interaction, Jalali picker, persistence, notifications, privacy deletion, TalkBack, large text, and upgrade continuity signed off

## Explicit blockers

The release must not be described as complete while any maintainer-owned gate is missing. CI cannot create legal identity, accept store contracts, prove possession of a safely backed-up permanent key, or replace physical accessibility/device testing.
