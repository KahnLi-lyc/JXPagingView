# JXPagingView UIKit Demo

下载本仓库后直接打开 `JXPagingViewDemo.xcodeproj`，选择同名 Scheme 和 Simulator 运行。Demo 只引用上一级本地 Package，不需要 JXSegmentedView、CocoaPods、网络图片或业务项目。正式分发仍只有库 Product，Demo 不进入 SPM 源码范围。

- 应用／库：Swift 6 语言模式、iOS 16+。本机新版 XCTest 框架最低 iOS 17，因此测试宿主目标为 iOS 17+；这不提高库或 Demo App 的系统下限。
- 工程来源：`project.yml`，XcodeGen **2.46.0**。修改文件列表／构建配置后，在仓库根运行 `xcodegen generate --spec Demo/project.yml`，一起提交工程和共享 Scheme。
- 每个示例从 `CatalogController` 进入 `PagingDemoController`；`DemoList` 展示保留自身 delegate、同步转发滚动通知的最小实现；`DemoListController` 展示控制器列表接入。

## 运行与操作

目录包含普通两种容器、刷新、Smooth、Header、缓存、控制器列表、手势、嵌套和独立列表容器十个入口。顶部按钮可切页、重载、切换 Header 180／260、吸顶、更新数据或启用缓存。`Data` 依次执行空列表、恢复并重排、插入、删除、恢复初始集合。`Options` 提供横向滚动、吸顶偏移、滚动指示器、预加载阈值、嵌套、创建门禁和内容高度操作，只显示当前 API 家族适用的项。

`Refresh` 通过原生 UIRefreshControl 的 valueChanged 事件开始刷新，三秒后完成；也可直接下拉。刷新示例仅使用 scrollView 容器：上游 collectionView 的 Cell 回收会干扰刷新，不作为受支持组合示范。Smooth 独立使用自己的数据源、KVO 和集合视图，不套用普通分页的缓存或偏移设置。

状态面板读取实际 `currentIndex`、`validListDict`／`listDict`、实例序号、Header 坐标、滚动偏移和原生刷新状态。生命周期日志由真实列表协议回调记录。返回目录后显示控制器和列表弱引用是否释放，不在 deinit 中操作 UIKit。

目录右上角环境菜单影响随后打开的场景：深浅色、RTL 和减少动画。实际系统 Reduce Motion 也会关闭 Header 动画。RTL 的宿主视觉布局与逻辑索引分开处理，不承诺库自动镜像。

## 最小接入

```swift
@MainActor
func makePaging(delegate: any JXPagingViewDelegate) -> JXPagingView {
    // delegate 提供 Header、pin Header、高度、数量和列表工厂。
    JXPagingView(delegate: delegate, listContainerType: .scrollView)
}

// 列表持有自己的 UIScrollViewDelegate，并保留组件注册的同步回调：
func scrollViewDidScroll(_ scrollView: UIScrollView) {
    callback?(scrollView)
}
```

宿主需强持有数据源和列表内容。普通容器管理控制器列表 containment，UIView 列表由宿主管理自身内容。设置非首项时同步标签控件与 defaultSelectedIndex。原生标签点击后调用 `didClickSelectedItem(at:)` 并设置内容滚动视图位置；滑动通过公开 contentOffset 观察同步标签，不接管组件 delegate。

## 自动化

在仓库根使用自己创建并完成 bootstatus 的设备：

```sh
scripts/test-demo.sh <dedicated-booted-simulator-uuid> /tmp/jxpaging-demo-fresh
```

输出包含完整日志、独立 DerivedData 和 Demo.xcresult；脚本检查实际 App 包中的 Package 隐私资源及并发诊断。iPad 重点流程可加 `-only-testing:JXPagingViewDemoUITests/DemoUITests/testSwipeAndRotationOnPhoneAndPad`。工程一致性检查需暂存／提交新工程后执行 `scripts/check-demo-project.sh`。

[功能覆盖和边界](COVERAGE.md)。UI 自动化断言行为，不等同于颜色、帧动画和真实 VoiceOver 验收。
