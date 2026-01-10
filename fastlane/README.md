fastlane documentation
----

# App Store Connect API Key Setup

To enable TestFlight uploads and App Store submissions without 2FA prompts:

1. **Create API Key in App Store Connect**
   - Go to [App Store Connect](https://appstoreconnect.apple.com) > Users and Access > Keys
   - Click the "+" button to generate a new API key
   - Name: `W8Trackr Fastlane` (or similar)
   - Access: `App Manager` role
   - Click "Generate"

2. **Download and Note Credentials**
   - Download the `.p8` file immediately (only downloadable once!)
   - Copy the **Key ID** (shown in the keys list)
   - Copy the **Issuer ID** (shown at the top of the keys page)

3. **Create api_key.json**
   ```bash
   cp fastlane/api_key.json.example fastlane/api_key.json
   ```
   Edit `fastlane/api_key.json` and fill in:
   - `key_id`: Your Key ID from step 2
   - `issuer_id`: Your Issuer ID from step 2
   - `key`: Contents of your `.p8` file (keep the BEGIN/END markers, use `\n` for newlines)

4. **Verify Setup**
   ```bash
   bundle exec fastlane beta
   ```

> **Security Note**: `fastlane/api_key.json` is gitignored. Never commit API keys!

----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios test

```sh
[bundle exec] fastlane ios test
```

Run unit tests

### ios build

```sh
[bundle exec] fastlane ios build
```

Build the app

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build and upload to TestFlight

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
