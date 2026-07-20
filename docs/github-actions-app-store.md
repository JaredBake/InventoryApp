# App Store from Windows with GitHub Actions

This project includes two iOS workflows in `.github/workflows/`:

- `ios-validation.yml`: Builds iOS without signing on macOS runners.
- `ios-app-store.yml`: Builds a signed IPA and uploads to TestFlight using App Store Connect API key auth.
- `ios-app-store-submit.yml`: Builds a signed IPA, uploads it, and submits the version for App Review.

## 1) Required GitHub secrets

Set these under: `GitHub repo -> Settings -> Secrets and variables -> Actions`.

- `IOS_BUNDLE_ID`
- `IOS_TEAM_ID`
- `IOS_DIST_CERT_BASE64` (base64 of your iOS Distribution certificate `.p12`)
- `IOS_DIST_CERT_PASSWORD` (password for the `.p12` file)
- `IOS_PROVISION_PROFILE_BASE64` (base64 of App Store provisioning profile `.mobileprovision`)
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_BASE64` (base64 of `AuthKey_XXXXXX.p8`)
- `APP_STORE_CONNECT_APP_ID` (optional but recommended numeric Apple app id from App Store Connect)

## 2) How to generate base64 values

Use Git Bash (or any shell) and paste the output as the secret value.

```bash
base64 -w 0 your-cert.p12
base64 -w 0 your-profile.mobileprovision
base64 -w 0 AuthKey_ABC123XYZ.p8
```

If your shell does not support `-w 0`, use:

```bash
base64 your-cert.p12 | tr -d '\n'
```

## 3) Run validation workflow

The `iOS Validation` workflow runs automatically on pushes and pull requests to `main`.

## 4) Run TestFlight release workflow (manual)

1. Open `GitHub repo -> Actions -> iOS App Store Release`.
2. Click `Run workflow`.
3. Provide:
   - `build_name` (example: `1.2.0`)
   - `build_number` (example: `120`)
4. Wait for the `Upload to TestFlight` step to complete.

## 5) Run App Store submit workflow (manual)

1. Open `GitHub repo -> Actions -> iOS App Store Submit`.
2. Click `Run workflow`.
3. Provide:
   - `build_name` (example: `1.2.0`)
   - `build_number` (example: `120`)
   - `automatic_release` (`true` or `false`)
4. Wait for `Upload to App Store and submit for review` to complete.

## 6) Important notes

- You still need an Apple Developer account.
- Apple signing assets must match the `Runner` target bundle identifier.
- For the submit workflow to succeed, your app listing, privacy info, and required App Store fields must already be configured in App Store Connect.
