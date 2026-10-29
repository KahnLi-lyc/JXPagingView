# 功能覆盖与验收边界

本表针对当前维护分支的 Swift 公开 API；不恢复上游 Objective-C、MJRefresh 或旧第三方全屏返回组件。每个入口都有自动冒烟，配置组合通过固定示例和操作项覆盖，不穷举排列。机器可读索引为 `coverage.json`。

| 能力 | 入口／操作 | 自动化证据（测试方法） | 人工状态／限制 |
| --- | --- | --- | --- |
| 两种容器、非首项、惰性创建、长短列表 | scroll / collection；Next、手动滑动 | EveryCatalogEntry…；BothContainersLazySelectionLifecycleAndRelease | 视觉连续性待人工 |
| 实际分页、旋转、iPad 布局 | scroll；横向滑动／横屏 | SwipeAndRotationOnPhoneAndPad | 真机待执行 |
| 吸顶／回落、Header 高度和偏移 | header；Header、Pin、Options | PinOffsetAndHeaderResizeUseActualGeometry；HeaderEmptyRestoreAndCacheIdentity | 动画视觉、手动回落待人工 |
| 原生刷新、刷新期间切页及结束 | refresh；下拉或 Refresh、Next | RefreshSurvivesSwitchAndEnds；RefreshRemainsActiveWhenSwitchingScrollContainer | collection+刷新不作为支持组合 |
| Smooth 连续滚动、Header、重载、内容高度 | smooth；Header、Pin、Data、Options Grow | SmoothHeaderAndContentResize；SmoothReloadIgnoresOldListAndReleases | 连续滚动视觉待人工 |
| 稳定 ID 缓存、滚动位置、增删重排和空恢复 | cache；Reload、Data、Cache | StableCacheReordersPreservesInstanceAndScrollPosition；HeaderEmptyRestoreAndCacheIdentity | 缓存打开前已删除 ID 不保留 |
| UIView／UIViewController 列表、父子关系、显示回调 | scroll / controllers；Next、Reload、返回 | ControllerListsHaveContainmentAndReloadRemovesOldParent；BothContainers…；EveryCatalogEntry… | 系统转场完整观感待人工 |
| 自定义容器滚动视图、返回优先、主表手势代理 | gestures；横滑、系统边缘返回 | EveryCatalogEntry…（分页／释放） | 真实边缘手势待人工，未接第三方返回组件 |
| 嵌套横向内容、category nesting | nested；横向卡片、Options | EveryCatalogEntry…（外层分页） | 内外手势竞争待人工 |
| 独立容器、创建门禁、预加载阈值、背景 | container；Options | EveryCatalogEntry…（独立选择） | 门禁与阈值交互待人工 |
| 滚动通知、回调顺序、观察替换、释放 | 全部；切换、重复 Reload、返回 | 两类集成测试、原库 ConcurrencyLifecycleTests、目录弱引用断言 | 未使用析构操作 UI |
| 深浅色、RTL、长内容、Reduce Motion、VoiceOver | Environment；系统设置 | iPad／旋转自动化；原库 RTL 测试 | 深浅色／RTL／Reduce Motion 人工待执行；真实 VoiceOver 待执行 |
| 隐私资源 | 实际 App 产物 | scripts/check-demo-resources.py | 文件存在并解析，不代替隐私申报审计 |

自动化方法的完整名称见 Tests 与 UITests 源码；实际运行结果和工具链记录在 `docs/DEMO_VALIDATION.md`。未完成的人工检查保持“待执行”，不因为工程编译或入口冒烟通过而改为通过。
