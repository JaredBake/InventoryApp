# App Store Release from Windows

This project can be published to the App Store from a Windows laptop by using a cloud macOS CI build.

## What this repo already has

- iOS project scaffold in `ios/`
- iOS camera usage description in `ios/Runner/Info.plist`
- Codemagic pipeline template in `codemagic.yaml`

## Required accounts and access

1. Apple Developer Program membership (paid)
2. App Store Connect access for your Apple account
3. Codemagic account connected to this repository

## One-time App Store Connect setup

1. Create your app record in App Store Connect.
2. Set a unique Bundle ID in Apple Developer and use the same value in App Store Connect.
3. Create an App Store Connect API key with access to Certificates, Identifiers and Profiles.
4. In Codemagic, create an App Store Connect integration using that API key.

## One-time repository setup

1. Open `codemagic.yaml`.
2. Replace `REPLACE_WITH_ASC_INTEGRATION_NAME` with your Codemagic integration name.
3. Replace `com.example.inventoryapp` with your real bundle identifier.
4. Commit and push these changes to `main`.

## First iOS build from Windows

1. In Codemagic, open this app and start workflow `ios-app-store`.
2. Wait for build and signing to finish.
3. Verify the IPA artifact is produced.
4. Confirm upload to TestFlight succeeded.

## TestFlight to App Store

1. In App Store Connect, open your app and verify the build appears in TestFlight.
2. Add internal testers and complete a smoke test.
3. Fill App Store metadata:
   - App description
   - Privacy policy URL
   - Support URL
   - Screenshots
   - Age rating
4. Complete App Privacy questionnaire.
5. Submit the tested build for App Review.

## Common issues and fixes

- Signing failure: bundle identifier in `codemagic.yaml` does not match App Store Connect.
- No build in TestFlight: check Codemagic publishing logs for App Store Connect authentication failures.
- Camera prompt missing on iOS: ensure `NSCameraUsageDescription` exists in `ios/Runner/Info.plist`.

## Notes

- You can keep all feature development on Windows.
- iOS compile/sign/distribution is handled by Codemagic macOS runners.
