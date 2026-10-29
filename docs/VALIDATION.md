# Swift 6 维护验收（2026-10-29）

本节为当前 SPM 分发结果；下方原始记录是历史基线，不代表当前仍采用 Swift 5。

- 环境：Xcode 27.1 (27A9275)，Apple Swift 6.4，iPhone 17 Pro / iOS 27.0 专用 Simulator。
- 发布要求：Swift tools 6.0、Swift 6 语言模式、最低 iOS 16。
- 源码回归提交：`c5a8354`；7 项独立 XCTest，0 failures。
- 原有基线：分页 2 项、分段 12 项先执行通过，再进行源码修改。
- 适配前直接 swiftc 完整检查：分页 Swift 5 有 12 条诊断，Swift 6 因协议隔离失败；分段 Swift 5 有 88 条诊断，Swift 6 在首批协议隔离错误终止。数字只描述该次编译输出，不是独立缺陷数量。
- 适配后全部库源码直接在 Swift 5 complete 和 Swift 6 complete 下 typecheck 均成功，无并发诊断。
- Swift 5、Swift 6 两个公开接口宿主分别构建成功；库在两种宿主构建中均保持 Swift 6。
- 实际 SwiftFileList 包含 5 个库 Swift 源文件及 1 个 SwiftPM 资源访问器；无额外 OC 源码参与。构建产物中的 PrivacyInfo.xcprivacy 经实际 bundle XCTest 读取通过。
- shell 语法、manifest dump、隐私 plist、Markdown 本地链接、git diff --check 通过；并发诊断门禁通过。

## 组合验证

ClubCircleUI 仅在临时快照中连接本地两个 fork。旧适配器移除不再适用的 nonisolated / assumeIsolated / preconcurrency 边界，滚动闭包声明 MainActor，正式工程和锁文件不变。

已执行 26 项相关消费者单元测试和 4 项 Demo UI 测试，均无失败。覆盖分段栏、普通分页、吸顶分页、页面缓存、重入应用、生命周期、清理、Header 高度变化、旋转和 RTL。此结果证明迁移后的适配器可以组合使用，不代表旧消费者源码可无修改升级。

## 诊断与边界

- 新增并发诊断：0。分页库和两个分页宿主无源码警告；分段库保留上游 automaticallyAdjustsScrollViewInsets 弃用诊断，避免改变原有宿主 inset 行为。
- Xcode 的 test sysroot、AppIntents metadata extraction 诊断独立记录。Demo 还存在 JPImageresizerView 等其它依赖诊断，不归为当前 fork 新增警告。
- 托管 GitHub Actions 配置已加入；本地验证不能代表远端 runner 已执行成功。远端运行状态须独立查看。
- 未验证最低 Swift 6.0 编译器、iOS 16 运行时、iPad／真机、实际 VoiceOver 朗读和完整无障碍体验；本机仅上述工具链和专用 iPhone Simulator。
- 本轮没有升级真实消费者 revision，没有修改其它三个通用库或上游源码基线。
- 本机验收材料保存在 SwiftLibraries 下 `.validation/2026-10-29-swift6/`；包含日志、结果摘要、xcresult 和临时消费者迁移补丁。DerivedData 不作为交付材料。

---

## 历史验证记录

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
