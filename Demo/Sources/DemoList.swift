import UIKit
import JXPagingView

/// 列表保留自己的 delegate，并同步转发滚动通知；不让分页组件接管 delegate。
final class DemoList: UIView, UITableViewDataSource, UITableViewDelegate, JXPagingViewListViewDelegate, JXPagingSmoothViewListViewDelegate {
    let table = UITableView(frame: .zero, style: .plain)
    let identifier: String
    let serial: Int
    let probe: ReleaseProbe
    var callback: (@MainActor (UIScrollView) -> Void)?
    var stateChanged: (@MainActor () -> Void)?
    var rows: Int
    var refreshCount = 0
    var nestedScroll: UIScrollView?

    init(id: String, serial: Int, rows: Int, refresh: Bool, nested: Bool, probe: ReleaseProbe) {
        identifier = id; self.serial = serial; self.rows = rows; self.probe = probe
        super.init(frame: .zero)
        table.dataSource = self; table.delegate = self
        table.accessibilityIdentifier = "list.\(id)"
        table.contentInsetAdjustmentBehavior = .never
        table.backgroundColor = .systemBackground
        addSubview(table)
        if refresh {
            let control = UIRefreshControl()
            control.addTarget(self, action: #selector(startRefresh), for: .valueChanged)
            table.refreshControl = control
        }
        if nested {
            let scroll = UIScrollView(frame: CGRect(x: 0, y: 0, width: 800, height: 88))
            scroll.contentSize = CGSize(width: 1600, height: 88)
            scroll.accessibilityIdentifier = "nested"
            scroll.delegate = self
            for index in 0..<6 {
                let label = UILabel(frame: CGRect(x: index * 240, y: 0, width: 220, height: 88))
                label.text = "Horizontal card \(index + 1)"; label.backgroundColor = .secondarySystemBackground
                scroll.addSubview(label)
            }
            table.tableHeaderView = scroll
            nestedScroll = scroll
        }
        probe.record("create:\(id)#\(serial)")
        probe.lists.append(WeakList(self))
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) unavailable") }
    override func layoutSubviews() { super.layoutSubviews(); table.frame = bounds }
    func listView() -> UIView { self }
    func listScrollView() -> UIScrollView { table }
    func listViewDidScrollCallback(callback: @escaping @MainActor (UIScrollView) -> Void) { self.callback = callback }
    func listScrollViewWillResetContentOffset() { probe.record("reset:\(identifier)") }
    func listWillAppear() { probe.record("willAppear:\(identifier)") }
    func listDidAppear() { probe.record("didAppear:\(identifier)"); stateChanged?() }
    func listWillDisappear() { probe.record("willDisappear:\(identifier)") }
    func listDidDisappear() { probe.record("didDisappear:\(identifier)"); stateChanged?() }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === table { callback?(scrollView) }
        stateChanged?()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = "\(identifier) — Row \(indexPath.row + 1)"
        cell.detailTextLabel?.text = "Instance #\(serial) · public UIKit list"
        return cell
    }
    @objc func startRefresh() {
        table.refreshControl?.beginRefreshing()
        refreshCount += 1
        probe.record("refresh:\(identifier)")
        stateChanged?()
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard let self else { return }
            table.refreshControl?.endRefreshing(); stateChanged?()
        }
    }
}

/// 普通分页容器负责 UIViewController containment；Smooth 的宿主显式管理。
final class DemoListController: UIViewController, JXPagingViewListViewDelegate, JXPagingSmoothViewListViewDelegate {
    let content: DemoList
    init(content: DemoList) { self.content = content; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) unavailable") }
    override func loadView() { view = content }
    func listView() -> UIView { view }
    func listScrollView() -> UIScrollView { content.table }
    func listViewDidScrollCallback(callback: @escaping @MainActor (UIScrollView) -> Void) { content.listViewDidScrollCallback(callback: callback) }
    func listWillAppear() { content.listWillAppear() }
    func listDidAppear() { content.listDidAppear() }
    func listWillDisappear() { content.listWillDisappear() }
    func listDidDisappear() { content.listDidDisappear() }
    func listScrollViewWillResetContentOffset() { content.listScrollViewWillResetContentOffset() }
}

/// 系统边缘返回手势优先，不替换导航控制器的 gesture delegate。
final class EdgeAwareScrollView: UIScrollView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        var responder: UIResponder? = self
        while let current = responder {
            if let controller = current as? UIViewController,
               let edge = controller.navigationController?.interactivePopGestureRecognizer {
                panGestureRecognizer.require(toFail: edge)
                break
            }
            responder = current.next
        }
    }
}
