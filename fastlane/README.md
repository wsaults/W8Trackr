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

### ios release

```sh
[bundle exec] fastlane ios release
```

Submit to App Store (metadata and screenshots only)

Assumes binary already uploaded via beta lane

### ios submit

```sh
[bundle exec] fastlane ios submit
```

Submit to App Store and request review

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Capture App Store screenshots using snapshot

### ios frames

```sh
[bundle exec] fastlane ios frames
```

Add device frames to screenshots using frameit

### ios screenshots_framed

```sh
[bundle exec] fastlane ios screenshots_framed
```

Capture screenshots and add device frames

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
