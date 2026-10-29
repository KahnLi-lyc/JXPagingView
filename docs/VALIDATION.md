# Validation recorded 2026-10-29

Environment: Xcode 27.1 (27A9275), Apple Swift 6.4, iOS 27.0 Simulator,
iPhone 17 Pro. Dedicated test device:
`94435F39-3E09-4B3B-AFB7-C322B1F12A2F` (`CC Dependency Forks 20261029`).

## Baseline

The exact upstream package at
`a55dd07adfa9729677e2287943af5aa40f5df31f` emitted:

```text
Invalid Resource 'Sources/PrivacyInfo.xcprivacy': File not found.
```

Although the baseline library build completed, it did not package the privacy
manifest. Adding the resource regression before the manifest fix caused the
standalone test build to fail (exit 65): `Type 'Bundle' has no member 'module'`.
This is the missing generated resource accessor, not a runtime failure.

## After manifest correction and distribution slimming

```sh
scripts/test-ios.sh 94435F39-3E09-4B3B-AFB7-C322B1F12A2F /tmp/cc-jxpaging-derived
xcodebuild -scheme JXPagingView \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/cc-jxpaging-derived build
```

- XCTest: **2 tests, 0 failures**, `TEST SUCCEEDED`, exit 0.
- Generic iOS Simulator build: `BUILD SUCCEEDED`, exit 0.
- The generated `JXPagingView_JXPagingView.bundle/PrivacyInfo.xcprivacy` exists
  both as a build product and in the test bundle; the XCTest reads its actual
  property list and confirms `NSPrivacyTracking = false`.
- `plutil -lint Sources/PrivacyInfo.xcprivacy`: OK.
- `swift package dump-package` and `git diff --check`: pass.
- `git diff -- Sources/JXPagingView`: empty (all five library files unchanged).

Ephemeral local logs:

- `/tmp/cc-jxpaging-red.log` (baseline warning).
- `/tmp/cc-jxpaging-red-test.log` (baseline resource regression failure).
- `/tmp/cc-jxpaging-green.log` (2 passing tests).
- `/tmp/cc-jxpaging-build-green.log` (generic build).

The RTL-parent test checks logical indices and initialization for both container
types. App visual mirroring, nested gesture behavior and physical devices require
host-level validation.

A final invocation of the checked-in `scripts/test-ios.sh` against the same
isolated Simulator also passed **2 tests, 0 failures**, exit 0. Evidence:
`/tmp/cc-jxpaging-final.log`.

## Master maintenance migration — 2026-10-29

The migration worktree retains the tested source tree from `76740c71b212b9ac491763e36a5744d73bc9c172`.
`Sources`, `Tests`, `Package.swift`, `LICENSE`, and `scripts/test-ios.sh` are byte-identical
to that revision. Only README and maintenance documents change.
The old master `8aa5663720ebfab0c4df41cfca04b113f832c5b2` is retained as the second parent of a
one-time history reconciliation; its later upstream source changes are not adopted.
See [the review ledger](UPSTREAM_REVIEW.md).

A dedicated iPhone 17 Pro / iOS 27 Simulator `A2FF0624-DBA8-48E2-B504-8547CF5C1783` ran the
actual SwiftPM package tests with Xcode 27.1 / Swift 6.4:

```sh
xcodebuild -jobs 2 -scheme JXPagingView -destination platform=iOS\ Simulator,id=A2FF0624-DBA8-48E2-B504-8547CF5C1783 -parallel-testing-enabled NO -collect-test-diagnostics never test
```

- **2 tests, 0 failures**, `TEST SUCCEEDED`, exit 0.
- `swift package dump-package`, shell syntax, privacy manifest lint, Markdown local
  links, unchanged runtime-tree comparison and `git diff --check`: pass.
- Xcode test sysroot / AppIntents metadata diagnostics were recorded separately. No warning was suppressed or source modified to silence it.
- Test log: `/var/folders/99/z2m_xqws3mq2jll1t05vm0fc0000gn/T/jx-master-migration-20261029-1ftt_bvl/JXPagingView-test.log`.
- Result bundle: `/var/folders/99/z2m_xqws3mq2jll1t05vm0fc0000gn/T/jx-master-migration-20261029-1ftt_bvl/JXPagingView.xcresult`.

The command used a fresh external DerivedData directory and result bundle, with
`-jobs 2` to limit machine load. Only verbose failure diagnostic collection was
disabled; test assertions and package compilation were unchanged. Existing
consumer revisions remain pinned; this is not a Swift 6 language-mode migration
or a new physical-device / consumer-application validation.
