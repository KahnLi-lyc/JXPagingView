> 自有 master 现面向 Swift 6.0+ 工具链、Swift 6 语言模式和 iOS 16+。
> 升级前阅读 [Swift 6 迁移指南](docs/SWIFT6_MIGRATION.md)；原上游说明中的旧系统／工具链范围不再适用于当前 SPM 分发。

# JXPagingView — Independently maintained SwiftPM fork

A Swift UIKit paging container for vertically coordinated headers and horizontally
paged lists. This fork ships the upstream Swift implementation as one SwiftPM
library; Objective-C, vendored example dependencies, and CocoaPods distribution
are intentionally absent from the maintained `master` distribution.

## Provenance and license

- Fork: https://github.com/KahnLi-lyc/JXPagingView (`master` maintenance branch).
- Upstream: https://github.com/pujiaxin33/JXPagingView
- Exact base: `a55dd07adfa9729677e2287943af5aa40f5df31f` (2.1.3).
- The original [MIT license](LICENSE) and Swift source author notices are retained.
- [Upstream documentation and examples at the base revision](https://github.com/pujiaxin33/JXPagingView/tree/a55dd07adfa9729677e2287943af5aa40f5df31f)
  remain available in the upstream repository.

## Swift Package Manager

Add `https://github.com/KahnLi-lyc/JXPagingView` and pin a reviewed full commit
from `master`. Link product `JXPagingView`, then `import JXPagingView`.
The old `spm` branch is frozen for existing consumers. See the
[branching guide](docs/BRANCHING.md) for maintenance and upstream updates.

The package target uses `path: "Sources"`, `sources: ["JXPagingView"]`, Swift 5
language mode, and copies `PrivacyInfo.xcprivacy` into its SwiftPM resource bundle.
All five upstream Swift files remain under `Sources/JXPagingView`. The main
classes are `JXPagingView`, `JXPagingListContainerView`, `JXPagingListRefreshView`,
and `JXPagingSmoothView`.

Lists conform to `JXPagingViewListViewDelegate`; `JXPagingViewDelegate` supplies
header, pinned header, and list configuration. Keep segmented selection and the
list container's logical index in sync. This fork preserves upstream paging and
layout behavior; text direction and any visual mirroring belong to the host's
layout policy.

## Verification

Use Xcode with a dedicated booted iOS Simulator:

```sh
scripts/test-ios.sh <simulator-uuid>
```

The tests import the actual package, check its bundled privacy manifest, and
exercise both list container types inside a parent with forced RTL semantics.
See [maintenance](docs/MAINTENANCE.md) and [recorded validation](docs/VALIDATION.md).
