import UIKit

/// 稳定路由同时用于示例目录、覆盖表及 UI 自动化。
enum PagingRoute: String, CaseIterable {
    case scroll, collection, refresh, smooth, header, cache, controllers, gestures, nested, container

    var title: String {
        switch self {
        case .scroll: "Scroll container"
        case .collection: "Collection / initial page 2"
        case .refresh: "Refresh while switching"
        case .smooth: "Smooth paging"
        case .header: "Header height & pin offset"
        case .cache: "Stable ID cache & data changes"
        case .controllers: "UIViewController lists"
        case .gestures: "Custom scroll & back gesture"
        case .nested: "Nested horizontal content"
        case .container: "Standalone list container"
        }
    }
}

@MainActor
final class DemoEnvironment {
    static let shared = DemoEnvironment()
    var rtl = false
    var reducedMotion = false
    var appearance = UIUserInterfaceStyle.unspecified
}

@MainActor
final class ReleaseProbe {
    weak var controller: UIViewController?
    var lists: [WeakList] = []
    var events: [String] = []
    func record(_ event: String) { events.append(event); if events.count > 80 { events.removeFirst() } }
    var aliveLists: Int { lists.filter { $0.value != nil }.count }
}

@MainActor
final class WeakList {
    weak var value: AnyObject?
    init(_ value: AnyObject) { self.value = value }
}

final class CatalogController: UITableViewController {
    let probe = ReleaseProbe()
    let releaseLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "JXPagingView Demo"
        tableView.accessibilityIdentifier = "catalog"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Environment", menu: UIMenu(children: [
            UIAction(title: "Toggle RTL") { [weak self] _ in
                DemoEnvironment.shared.rtl.toggle()
                self?.applyEnvironment()
            },
            UIAction(title: "Toggle dark / light") { [weak self] _ in
                DemoEnvironment.shared.appearance = DemoEnvironment.shared.appearance == .dark ? .light : .dark
                self?.applyEnvironment()
            },
            UIAction(title: "Toggle reduced motion") { _ in DemoEnvironment.shared.reducedMotion.toggle() }
        ]))
        releaseLabel.numberOfLines = 0
        releaseLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        releaseLabel.accessibilityIdentifier = "release"
        releaseLabel.frame.size.height = 88
        tableView.tableFooterView = releaseLabel
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 等待导航过渡释放旧控制器后再读取弱引用，不借助析构访问 UIKit。
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard let self else { return }
            releaseLabel.text = "Released scene: \(probe.controller == nil); live lists: \(probe.aliveLists)"
        }
    }

    private func applyEnvironment() {
        navigationController?.overrideUserInterfaceStyle = DemoEnvironment.shared.appearance
        view.semanticContentAttribute = DemoEnvironment.shared.rtl ? .forceRightToLeft : .forceLeftToRight
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { PagingRoute.allCases.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let route = PagingRoute.allCases[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = route.title
        cell.detailTextLabel?.text = route.rawValue
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityIdentifier = "route.\(route.rawValue)"
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let controller = PagingDemoController(route: PagingRoute.allCases[indexPath.row], probe: probe)
        releaseLabel.text = "Checking current scene release…"
        probe.controller = controller
        navigationController?.pushViewController(controller, animated: true)
    }
}
