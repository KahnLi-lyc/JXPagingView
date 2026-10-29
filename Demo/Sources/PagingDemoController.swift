import UIKit
import JXPagingView

/// 完整可操作宿主；所有依赖均通过公开 API 接入。
final class PagingDemoController: UIViewController, JXPagingViewDelegate, JXPagingSmoothViewDataSource, JXPagingSmoothViewDelegate, JXPagingListContainerViewDataSource, JXPagingMainTableViewGestureDelegate {
    let route: PagingRoute
    let probe: ReleaseProbe
    var paging: JXPagingView?
    var smooth: JXPagingSmoothView?
    var standalone: JXPagingListContainerView?
    let host = UIView()
    let header = UILabel()
    let tabs = UISegmentedControl(items: ["Alpha", "Beta", "Gamma"])
    let snapshot = UILabel()
    let events = UILabel()
    var headerHeight = 180
    var ids = ["Alpha", "Beta", "Gamma"]
    var created = 0
    var dataStep = 0
    var blocked = false
    var horizontalEnabled = true
    var lists: [WeakList] = []
    private var refreshingSnapshot = false
    private var scrollObservation: NSKeyValueObservation?

    init(route: PagingRoute, probe: ReleaseProbe = ReleaseProbe()) {
        self.route = route; self.probe = probe
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) unavailable") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = route.title
        view.backgroundColor = .systemBackground
        overrideUserInterfaceStyle = DemoEnvironment.shared.appearance
        // RTL 的可视镜像由宿主管理；索引仍按数据顺序解释。
        view.semanticContentAttribute = DemoEnvironment.shared.rtl ? .forceRightToLeft : .forceLeftToRight
        header.text = "Shared header · 180pt"
        header.textAlignment = .center
        header.backgroundColor = .secondarySystemBackground
        header.accessibilityIdentifier = "paging.header"
        tabs.accessibilityIdentifier = "tabs"
        tabs.selectedSegmentIndex = route == .collection ? 1 : 0
        tabs.addTarget(self, action: #selector(tabChanged), for: .valueChanged)
        snapshot.numberOfLines = 0; snapshot.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        snapshot.accessibilityIdentifier = "snapshot"
        events.numberOfLines = 2; events.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        events.accessibilityIdentifier = "events"
        let controls = UIStackView(arrangedSubviews: [
            row([("Next", "next", #selector(nextPage)), ("Reload", "reload", #selector(reload)), ("Header", "header", #selector(resizeHeader)), ("Pin", "pin", #selector(pinHeader))]),
            row([("Data", "data", #selector(changeData)), ("Cache", "cache", #selector(toggleCache)), ("Refresh", "refresh", #selector(refresh)), ("Options", "options", #selector(showOptions))]),
            snapshot, events
        ])
        controls.axis = .vertical; controls.spacing = 4
        controls.translatesAutoresizingMaskIntoConstraints = false
        host.translatesAutoresizingMaskIntoConstraints = false
        host.accessibilityIdentifier = "paging.host"
        view.addSubview(controls); view.addSubview(host)
        NSLayoutConstraint.activate([
            controls.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            controls.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            controls.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            host.topAnchor.constraint(equalTo: controls.bottomAnchor, constant: 4),
            host.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            host.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        if route == .smooth {
            let smooth = JXPagingSmoothView(dataSource: self)
            smooth.delegate = self; self.smooth = smooth
            host.addSubview(smooth)
        } else if route == .container {
            let container = JXPagingListContainerView(dataSource: self, type: .scrollView)
            container.initListPercent = 0.2
            standalone = container
            host.addSubview(container)
            tabs.removeFromSuperview(); view.addSubview(tabs)
            // standalone 的标签使用导航标题区域，不与分页 Header 组合。
            navigationItem.titleView = tabs
        } else {
            let type: JXPagingListContainerType = route == .collection ? .collectionView : .scrollView
            let paging = route == .refresh ? JXPagingListRefreshView(delegate: self, listContainerType: .scrollView) : JXPagingView(delegate: self, listContainerType: type)
            self.paging = paging
            paging.defaultSelectedIndex = tabs.selectedSegmentIndex
            paging.allowsCacheList = route == .cache
            paging.pinSectionHeaderVerticalOffset = route == .header ? 20 : 0
            paging.listContainerView.isCategoryNestPagingEnabled = route == .nested
            paging.mainTableView.gestureDelegate = self
            host.addSubview(paging)
        }
        let scroll = smooth?.listCollectionView ?? paging?.listContainerView.scrollView ?? standalone?.scrollView
        // 只观察公开滚动视图，不替换组件自己的 delegate。
        scrollObservation = scroll?.observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
            precondition(Thread.isMainThread)
            MainActor.assumeIsolated { self?.syncSelection() }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        paging?.frame = host.bounds; smooth?.frame = host.bounds; standalone?.frame = host.bounds
        updateSnapshot()
    }

    private func row(_ buttons: [(String, String, Selector)]) -> UIStackView {
        let result = UIStackView()
        result.distribution = .fillEqually
        for (title, id, action) in buttons {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal); button.accessibilityIdentifier = id
            button.addTarget(self, action: action, for: .touchUpInside)
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            if id == "refresh" { button.isEnabled = route == .refresh }
            if id == "cache" { button.isEnabled = paging == nil && route != .smooth && route != .container }
            if id == "header" || id == "pin" { button.isEnabled = route != .container }
            result.addArrangedSubview(button)
        }
        return result
    }

    var actualIndex: Int {
        if let smooth, smooth.bounds.width > 0 {
            return Int((smooth.listCollectionView.contentOffset.x / smooth.bounds.width).rounded())
        }
        return paging?.listContainerView.currentIndex ?? standalone?.currentIndex ?? 0
    }
    private var activeLists: [DemoList] {
        let values: [AnyObject]
        if let paging { values = paging.validListDict.values.map { $0 as AnyObject } }
        else if let smooth { values = smooth.listDict.values.map { $0 as AnyObject } }
        else { values = standalone?.validListDict.values.map { $0 as AnyObject } ?? [] }
        return values.compactMap { ($0 as? DemoList) ?? ($0 as? DemoListController)?.content }
    }
    var currentList: DemoList? {
        let id = ids.indices.contains(actualIndex) ? ids[actualIndex] : ""
        return activeLists.first { $0.identifier == id }
    }
    func updateSnapshot() {
        guard isViewLoaded, !refreshingSnapshot else { return }
        refreshingSnapshot = true
        defer { refreshingSnapshot = false }
        let instances = activeLists.map { "\($0.identifier)#\($0.serial)" }.sorted().joined(separator: ",")
        let offset = Int(paging?.mainTableView.contentOffset.y ?? currentList?.table.contentOffset.y ?? 0)
        let refresh = activeLists.contains { $0.table.refreshControl?.isRefreshing == true }
        let headerY = header.superview == nil ? -999 : Int(header.convert(header.bounds, to: host).minY)
        let pinY = tabs.superview == nil ? -999 : Int(tabs.convert(tabs.bounds, to: host).minY)
        let visible = currentList?.table.window != nil && currentList!.table.convert(currentList!.table.bounds, to: host).intersects(host.bounds) ? currentList!.identifier : "none"
        snapshot.text = "selected=\(actualIndex); visible=\(visible); count=\(ids.count); created=\(created)\ninstances=\(instances)\nheader=\(headerHeight); offset=\(offset); headerY=\(headerY); pinY=\(pinY); refreshing=\(refresh); cache=\(paging?.allowsCacheList == true); nestedMoved=\((currentList?.nestedScroll?.contentOffset.x ?? 0) > 1)"
        events.text = probe.events.suffix(4).joined(separator: " → ")
    }
    func syncSelection() {
        if ids.indices.contains(actualIndex) { tabs.selectedSegmentIndex = actualIndex }
        updateSnapshot()
    }
    @objc func nextPage() { guard !ids.isEmpty else { return }; select((actualIndex + 1) % ids.count) }
    @objc func tabChanged() { select(tabs.selectedSegmentIndex) }
    func select(_ index: Int) {
        guard ids.indices.contains(index) else { return }
        let container = paging?.listContainerView ?? standalone
        if let container {
            container.didClickSelectedItem(at: index)
            container.scrollView.setContentOffset(CGPoint(x: CGFloat(index) * container.bounds.width, y: 0), animated: false)
        } else if let smooth {
            smooth.listCollectionView.setContentOffset(CGPoint(x: CGFloat(index) * smooth.bounds.width, y: 0), animated: false)
            smooth.listCollectionView.layoutIfNeeded()
        }
        tabs.selectedSegmentIndex = index
        updateSnapshot()
    }
    @objc func reload() { reloadPages(selectedIndex: actualIndex) }
    private func reloadPages(selectedIndex index: Int) {
        let selected = max(0, min(index, ids.count - 1))
        paging?.defaultSelectedIndex = selected
        smooth?.defaultSelectedIndex = selected
        standalone?.defaultSelectedIndex = selected
        paging?.reloadData(); smooth?.reloadData(); standalone?.reloadData()
        host.layoutIfNeeded()
        paging?.layoutIfNeeded(); paging?.listContainerView.layoutIfNeeded()
        standalone?.layoutIfNeeded()
        select(selected)
        updateSnapshot()
    }
    @objc func resizeHeader() {
        headerHeight = headerHeight == 180 ? 260 : 180
        header.text = "Shared header · \(headerHeight)pt"
        paging?.resizeTableHeaderViewHeight(animatable: !UIAccessibility.isReduceMotionEnabled && !DemoEnvironment.shared.reducedMotion)
        smooth?.defaultSelectedIndex = actualIndex
        smooth?.reloadData()
        updateSnapshot()
    }
    @objc func pinHeader() {
        if let paging {
            paging.mainTableView.setContentOffset(CGPoint(x: 0, y: headerHeight), animated: false)
        } else if let smooth, let list = currentList {
            list.table.setContentOffset(CGPoint(x: 0, y: -CGFloat(heightForPinHeader(in: smooth))), animated: false)
        }
        host.layoutIfNeeded(); updateSnapshot()
    }
    @objc func changeData() {
        dataStep = (dataStep + 1) % 5
        switch dataStep {
        case 1: ids = []
        case 2: ids = ["Gamma", "Beta", "Alpha"]
        case 3: ids = ["Gamma", "Delta", "Beta", "Alpha"]
        case 4: ids = ["Beta", "Alpha"]
        default: ids = ["Alpha", "Beta", "Gamma"]
        }
        tabs.removeAllSegments()
        for (index, id) in ids.enumerated() { tabs.insertSegment(withTitle: id, at: index, animated: false) }
        tabs.selectedSegmentIndex = ids.isEmpty ? UISegmentedControl.noSegment : 0
        reloadPages(selectedIndex: 0)
    }
    @objc func toggleCache() { paging?.allowsCacheList.toggle(); reload() }
    @objc func refresh() {
        guard route == .refresh else { return }
        currentList?.table.refreshControl?.sendActions(for: .valueChanged)
    }
    @objc private func showOptions() {
        let menu = UIAlertController(title: "Public configuration", message: "Apply to this scene; swipe content to inspect actual behavior.", preferredStyle: .actionSheet)
        func action(_ title: String, _ body: @escaping @MainActor () -> Void) {
            menu.addAction(UIAlertAction(title: title, style: .default) { _ in body() })
        }
        action("Toggle horizontal scrolling") { [weak self] in
            guard let self else { return }; horizontalEnabled.toggle()
            paging?.isListHorizontalScrollEnabled = horizontalEnabled
            smooth?.listCollectionView.isScrollEnabled = horizontalEnabled
            standalone?.scrollView.isScrollEnabled = horizontalEnabled
            updateSnapshot()
        }
        if let paging {
            action("Toggle pin offset 0 / 20") { [weak self, weak paging] in
                paging?.pinSectionHeaderVerticalOffset = paging?.pinSectionHeaderVerticalOffset == 0 ? 20 : 0
                self?.reload()
            }
            action("Toggle automatic scroll indicator") { [weak paging] in paging?.automaticallyDisplayListVerticalScrollIndicator.toggle() }
        }
        if let container = paging?.listContainerView ?? standalone {
            action("Toggle preload threshold .01 / .5") { [weak container] in container?.initListPercent = container?.initListPercent == 0.01 ? 0.5 : 0.01 }
            action("Toggle nesting & cell background") { [weak container] in
                container?.isCategoryNestPagingEnabled.toggle()
                container?.listCellBackgroundColor = .tertiarySystemBackground
            }
        }
        if route == .container {
            action("Toggle creation gate for page Beta") { [weak self] in self?.blocked.toggle(); self?.reload() }
        }
        action("Grow current list content") { [weak self] in
            self?.currentList?.rows = 100; self?.currentList?.table.reloadData(); self?.updateSnapshot()
        }
        menu.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        menu.popoverPresentationController?.sourceView = view
        menu.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: 130, width: 1, height: 1)
        present(menu, animated: true)
    }

    // MARK: - List factories
    private func makeList(_ index: Int) -> DemoList {
        created += 1
        let list = DemoList(id: ids[index], serial: created, rows: index == 1 ? 3 : 60, refresh: route == .refresh, nested: route == .nested, probe: probe)
        list.stateChanged = { [weak self] in self?.updateSnapshot() }
        lists.append(WeakList(list))
        return list
    }
    private func makeProvider(_ index: Int) -> any JXPagingViewListViewDelegate {
        let list = makeList(index)
        if route == .controllers { return DemoListController(content: list) }
        return list
    }
    // MARK: - Regular paging
    func tableHeaderViewHeight(in pagingView: JXPagingView) -> Int { headerHeight }
    func tableHeaderView(in pagingView: JXPagingView) -> UIView { header }
    func heightForPinSectionHeader(in pagingView: JXPagingView) -> Int { 48 }
    func viewForPinSectionHeader(in pagingView: JXPagingView) -> UIView { tabs }
    func numberOfLists(in pagingView: JXPagingView) -> Int { ids.count }
    func pagingView(_ pagingView: JXPagingView, initListAtIndex index: Int) -> any JXPagingViewListViewDelegate { makeProvider(index) }
    func pagingView(_ pagingView: JXPagingView, listIdentifierAtIndex index: Int) -> String? { ids[index] }
    func pagingView(_ pagingView: JXPagingView, mainTableViewDidScroll scrollView: UIScrollView) { updateSnapshot() }
    func pagingView(_ pagingView: JXPagingView, mainTableViewWillBeginDragging scrollView: UIScrollView) { probe.record("main:begin") }
    func pagingView(_ pagingView: JXPagingView, mainTableViewDidEndDragging scrollView: UIScrollView, willDecelerate decelerate: Bool) { probe.record("main:endDragging"); updateSnapshot() }
    func pagingView(_ pagingView: JXPagingView, mainTableViewDidEndDecelerating scrollView: UIScrollView) { probe.record("main:endDecelerating"); updateSnapshot() }
    func pagingView(_ pagingView: JXPagingView, mainTableViewDidEndScrollingAnimation scrollView: UIScrollView) { probe.record("main:endAnimation"); updateSnapshot() }
    func scrollViewClassInListContainerView(in pagingView: JXPagingView) -> AnyClass? { route == .gestures ? EdgeAwareScrollView.self : nil }
    func mainTableViewGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if route == .nested, let nested = currentList?.nestedScroll, nested.isDragging { return false }
        return gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer
    }
    // MARK: - Smooth (independent API family)
    func heightForPagingHeader(in pagingView: JXPagingSmoothView) -> CGFloat { CGFloat(headerHeight) }
    func viewForPagingHeader(in pagingView: JXPagingSmoothView) -> UIView { header }
    func heightForPinHeader(in pagingView: JXPagingSmoothView) -> CGFloat { 48 }
    func viewForPinHeader(in pagingView: JXPagingSmoothView) -> UIView { tabs }
    func numberOfLists(in pagingView: JXPagingSmoothView) -> Int { ids.count }
    func pagingView(_ pagingView: JXPagingSmoothView, initListAtIndex index: Int) -> any JXPagingSmoothViewListViewDelegate { makeList(index) }
    func pagingSmoothViewDidScroll(_ scrollView: UIScrollView) { syncSelection() }
    // MARK: - Standalone container
    func numberOfLists(in listContainerView: JXPagingListContainerView) -> Int { ids.count }
    func listContainerView(_ listContainerView: JXPagingListContainerView, initListAt index: Int) -> any JXPagingViewListViewDelegate { makeProvider(index) }
    func listContainerView(_ listContainerView: JXPagingListContainerView, canInitListAt index: Int) -> Bool { !(blocked && index == 1) }
    func scrollViewClass(in listContainerView: JXPagingListContainerView) -> AnyClass? { EdgeAwareScrollView.self }
}
