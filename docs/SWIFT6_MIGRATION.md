# Swift 6 迁移指南

本次维护将 SPM 分发的最低工具链提升至 Swift 6.0，正式使用 Swift 6 语言模式，最低系统为 iOS 16。模块和 product 名不变；Swift 5 模式宿主仍可用现代工具链接入，但 Swift 5.3 等旧工具链不能解析新 manifest。原来的完整 revision 和冻结 spm 分支继续可用。

## 主线程约定

所有 UI 数据源、代理、列表和展示状态均由主 Actor 管理。UIKit 子类继承隔离；NSObject 适配器建议显式声明 `@MainActor`。后台工作只产生数据，在 `await MainActor.run { ... }` 内更新组件。不要把 UIKit 对象声明为 unchecked Sendable。

此前为 Swift 5 第三方覆写添加的 `nonisolated` 应移除；原本同步的 UI 访问不再需要 `MainActor.assumeIsolated` 包装。隔离标注是有意的源码兼容变化，升级消费者前先编译其自定义子类和代理。公开名称、参数标签、默认值和同步交互保持原样，不承诺 ABI 兼容。

## KVO 与生命周期

内部通过受控 NSKeyValueObservation token 观察 UIKit 滚动属性；重载和替换先释放旧 token。保留 open observeValue 钩子及其 keyPath / object / change kind / event newValue。非隔离 Foundation 入口通过主线程前置检查同步进入 MainActor，不使用异步派发改变滚动顺序。UIKit 属性仍必须在主线程修改；这不提供跨线程修改 UIScrollView 的能力。

不在 deinit 调用 UIKit 或子页方法。宿主按既有约定管理控制器 containment 和生命周期；列表注册回调不得形成宿主自身的强引用环。

## 验证与持续集成

```sh
scripts/test-ios.sh <dedicated-simulator-uuid> /tmp/Library-DD -- -resultBundlePath /tmp/Library-tests.xcresult SWIFT_STRICT_CONCURRENCY=complete
scripts/check-consumer.sh /tmp/fresh-consumer-output
scripts/check-concurrency-diagnostics.sh /tmp/build.log
```

`Fixtures/Consumer` 使用公开 import，独立 Swift 5、Swift 6 target，各自明确语言模式，依赖库保持 Swift 6。不要全局覆盖 SWIFT_VERSION 来伪造宿主兼容测试。CI 在托管 macOS 默认 Xcode 上创建专用设备，串行执行回归与宿主构建，保存完整日志和 xcresult。并发警告门禁不屏蔽 SDK／弃用诊断。

工具链下限声明不等于最低工具链已运行验证；实际设备、系统、编译器和托管 CI 结果以 VALIDATION.md 为准。

## 分页 API

JXPagingViewDelegate、JXPagingViewListViewDelegate、列表容器数据源、Smooth 系列协议和手势代理均为 MainActor。

```swift
@MainActor
final class List: NSObject, JXPagingViewListViewDelegate {
    let scrollView = UIScrollView()
    var onScroll: (@MainActor (UIScrollView) -> Void)?
    func listView() -> UIView { scrollView }
    func listScrollView() -> UIScrollView { scrollView }
    func listViewDidScrollCallback(callback: @escaping @MainActor (UIScrollView) -> Void) {
        onScroll = callback
    }
    // 宿主自己的 scrollViewDidScroll 中同步调用 onScroll?(scrollView)。
}
```

库不替换子页 delegate。失效列表的旧滚动回调不能改变当前页，缓存列表重新接入时重新绑定回调。Smooth 的旧观察随 reload 失效，保留原有 contentSize 下限与同步滚动规则。
