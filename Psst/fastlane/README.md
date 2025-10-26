fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios ensure_app_exists

```sh
[bundle exec] fastlane ios ensure_app_exists
```

Ensure app exists in App Store Connect (creates if needed)

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Deploy a new beta build to TestFlight

Usage: fastlane beta

This will:

  1. Ensure clean git state

  2. Ensure app exists in App Store Connect

  3. Increment build number

  4. Sync certificates/profiles from Match

  5. Build the app

  6. Upload to TestFlight

  7. Commit build number bump

### ios release

```sh
[bundle exec] fastlane ios release
```

Deploy a new production build to App Store

Usage: fastlane release

Note: This uploads to App Store but does NOT submit for review.

Complete submission manually in App Store Connect.

### ios test

```sh
[bundle exec] fastlane ios test
```

Run unit and UI tests

Usage: fastlane test

Tests run on the 'Vanes' simulator

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Generate App Store screenshots

Usage: fastlane screenshots

Captures screenshots on iPhone 15 Pro and iPad Pro

### ios create_app

```sh
[bundle exec] fastlane ios create_app
```

Create app in App Store Connect

Usage: fastlane create_app

This is automatically called by beta/release lanes, but can be run manually if needed

### ios match_dev

```sh
[bundle exec] fastlane ios match_dev
```

Setup Match for the first time (development certificates)

Usage: fastlane match_dev

### ios match_appstore

```sh
[bundle exec] fastlane ios match_appstore
```

Setup Match for the first time (App Store certificates)

Usage: fastlane match_appstore

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
