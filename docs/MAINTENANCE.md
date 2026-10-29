# Maintenance scope

The maintained `master` distribution is based on upstream JXPagingView 2.1.3,
`a55dd07adfa9729677e2287943af5aa40f5df31f`. The fork's Git history and
upstream tags are preserved. The old `spm` branch is frozen for compatibility.

The distribution removes `Sources/JXPagerView` (Objective-C), `Examples` (including
vendored Pods), and `JXPagingView.podspec`. No duplicate root Swift directory or
CI workflow exists at this exact base, so there is none to remove. The issue
templates and the original `Document` notes remain.

The upstream SwiftPM resource path was relative to `Sources/JXPagingView` but
pointed to `Sources/PrivacyInfo.xcprivacy` beneath that directory. Xcode emitted
`Invalid Resource 'Sources/PrivacyInfo.xcprivacy': File not found.` and produced
no resource accessor. The target now starts at `Sources`, explicitly includes
only `JXPagingView`, and copies the neighboring privacy manifest. The initial distribution advertised Swift 5 mode. The current distribution uses
Swift tools 6.0, Swift 6 language mode and iOS 16; actor isolation and owned KVO
observation are maintenance patches. See SWIFT6_MIGRATION.md for source changes.

`Tests/JXPagingViewTests` tests the package's `Bundle.module` resource and logical
selection of both collection-view and scroll-view containers under a forced RTL
parent. This is a package compatibility check, not proof of an application's
visual layout, interactive gesture policy, or integration behavior.

## Reproduce

```sh
scripts/test-ios.sh <dedicated-booted-simulator-uuid>
xcodebuild -scheme JXPagingView \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/JXPagingView-SPM-Build build
```

The package has no external dependencies. Run these checks before committing
future maintenance updates; do not replace upstream tags or rewrite master.

## Branch maintenance

`master` is the active default branch. Work on `feature/*` or `fix/*`, run the
package regressions, and merge into `master` before updating consumers.
The one-time history reconciliation keeps the tested `spm` source tree; it does
not adopt later upstream changes merely because their commits are ancestors.
See [branching](BRANCHING.md) and the explicit [upstream review ledger](UPSTREAM_REVIEW.md).

## Swift 6 maintenance

Current SPM requirements: Swift tools 6.0, Swift 6 language mode, iOS 16.
The adopted upstream release baseline is unchanged. Concurrency/lifecycle patches
are fork-owned; see [migration guide](SWIFT6_MIGRATION.md) and actual validation.
Original license, authorship and privacy resources are retained.
