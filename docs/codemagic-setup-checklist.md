# Codemagic Setup Checklist

Use this list to fill in the values needed for Windows-to-iPhone builds.

## 1) Apple account values

- Apple Developer Program membership: paid and active
- Apple ID email: your login email for Apple Developer / App Store Connect
- Team name: the Apple Developer team shown in Xcode / App Store Connect
- App-specific password: only if Codemagic asks for Apple login verification

## 2) App Store Connect values

- App name: the name you want in the App Store
- Bundle ID: must match the iOS app exactly, for example `com.yourname.inventoryapp`
- SKU: any unique internal string, for example `inventoryapp-ios-001`
- Primary language: usually English (U.S.)

## 3) Codemagic values

- Codemagic app connection: link your GitHub repo to Codemagic
- App Store Connect integration name: the name you create inside Codemagic after adding your API key
- Workflow name for validation: `ios-validation`
- Workflow name for release: `ios-app-store`

## 4) App Store Connect API key

Create this in App Store Connect and keep the following values:

- Issuer ID
- Key ID
- Private key file (`.p8`)

Codemagic needs these to authenticate and upload builds.

## 5) Signing values

- Certificate type: Apple Distribution
- Provisioning profile type: App Store
- Bundle ID must exactly match the app record and the `codemagic.yaml` file

## 6) Files in this repo that must match your values

- `codemagic.yaml`
- `ios/Runner/Info.plist`
- App Store Connect app record

## 7) Recommended order

1. Create or confirm the App Store Connect app record.
2. Create the App Store Connect API key.
3. Connect the repo in Codemagic.
4. Paste the integration name and Bundle ID into `codemagic.yaml`.
5. Run `ios-validation`.
6. Run `ios-app-store`.

## 8) Common mistakes

- Bundle ID mismatch between Apple and `codemagic.yaml`
- Missing App Store Connect API key permissions
- Trying to use a development profile instead of App Store distribution
- Forgetting to update `NSCameraUsageDescription` on iOS
