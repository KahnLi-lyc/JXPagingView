import XCTest
import UIKit
import JXPagingView

@MainActor
final class PublicIntegrationTests: XCTestCase {
    private func mount(_ view: UIView) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let controller = UIViewController()
        window.rootViewController = controller
        controller.loadViewIfNeeded()
        view.frame = controller.view.bounds; controller.view.addSubview(view)
        controller.beginAppearanceTransition(true, animated: false)
        view.layoutIfNeeded()
        controller.endAppearanceTransition()
        return window
    }
    func testBothContainersLazySelectionLifecycleAndRelease() {
        for type in [JXPagingListContainerType.scrollView, .collectionView] {
            let released = WeakReference(nil)
            let releasedList = WeakReference(nil)
            autoreleasepool {
                let source = Fixture()
                let paging = JXPagingView(delegate: source, listContainerType: type)
                released.value = paging
                let window = mount(paging)
                paging.reloadData(); paging.layoutIfNeeded()
                let baseline = source.created
                XCTAssertNotNil(paging.validListDict[0])
                XCTAssertNil(paging.validListDict[2])
                let first = paging.validListDict[0] as! TestList
                paging.listContainerView.didClickSelectedItem(at: 1)
                XCTAssertEqual(paging.listContainerView.currentIndex, 1)
                XCTAssertEqual(source.created, baseline + 1)
                XCTAssertTrue(first.events.suffix(2).elementsEqual(["willDisappear", "didDisappear"]))
                let second = paging.validListDict[1] as! TestList
                XCTAssertTrue(second.events.suffix(2).elementsEqual(["willAppear", "didAppear"]))
                releasedList.value = second
                paging.removeFromSuperview(); window.rootViewController = nil
            }
            XCTAssertNil(released.value)
            XCTAssertNil(releasedList.value)
        }
    }
    func testStableCacheReordersPreservesInstanceAndScrollPosition() {
        let source = Fixture()
        let paging = JXPagingView(delegate: source, listContainerType: .scrollView)
        paging.allowsCacheList = true
        let window = mount(paging); defer { window.isHidden = true }
        paging.reloadData()
        let first = paging.validListDict[0] as! TestList
        paging.mainTableView.contentOffset.y = CGFloat(source.height)
        first.scroll.contentOffset.y = 140
        source.ids = ["B", "A", "C"]
        paging.defaultSelectedIndex = 1; paging.reloadData(); paging.layoutIfNeeded()
        XCTAssertTrue(paging.validListDict[1] as AnyObject? === first)
        XCTAssertEqual(source.created, 1)
        XCTAssertEqual(first.scroll.contentOffset.y, 140)
    }
    func testPinOffsetAndHeaderResizeUseActualGeometry() {
        for type in [JXPagingListContainerType.scrollView, .collectionView] {
            let source = Fixture()
            let paging = JXPagingView(delegate: source, listContainerType: type)
            paging.pinSectionHeaderVerticalOffset = 20
            let window = mount(paging); defer { window.isHidden = true }
            paging.reloadData(); paging.layoutIfNeeded()
            paging.mainTableView.contentOffset.y = 180
            XCTAssertEqual(paging.mainTableView.contentOffset.y, 160, accuracy: 1)
            XCTAssertEqual(source.pin.convert(source.pin.bounds, to: paging).minY, 20, accuracy: 1)
            source.height = 260
            paging.resizeTableHeaderViewHeight(animatable: false)
            XCTAssertEqual(paging.mainTableView.tableHeaderView?.bounds.height, 260)
        }
    }
    func testRefreshRemainsActiveWhenSwitchingScrollContainer() {
        let source = Fixture()
        let paging = JXPagingListRefreshView(delegate: source, listContainerType: .scrollView)
        let window = mount(paging); defer { window.isHidden = true }
        paging.reloadData()
        let first = paging.validListDict[0] as! TestList
        first.scroll.refreshControl = UIRefreshControl()
        first.scroll.refreshControl?.beginRefreshing()
        paging.listContainerView.didClickSelectedItem(at: 1)
        paging.listContainerView.didClickSelectedItem(at: 0)
        XCTAssertTrue(first.scroll.refreshControl!.isRefreshing)
        XCTAssertTrue(paging.validListDict[0] as AnyObject? === first)
        first.scroll.refreshControl?.endRefreshing()
        XCTAssertFalse(first.scroll.refreshControl!.isRefreshing)
    }
    func testControllerListsHaveContainmentAndReloadRemovesOldParent() {
        let source = Fixture(); source.controllerLists = true
        let paging = JXPagingView(delegate: source, listContainerType: .scrollView)
        let window = mount(paging); defer { window.isHidden = true }
        paging.reloadData()
        let first = paging.validListDict[0] as! TestController
        XCTAssertNotNil(first.parent)
        paging.reloadData()
        XCTAssertNil(first.parent)
        XCTAssertNotNil((paging.validListDict[0] as! TestController).parent)
    }
    func testSmoothReloadIgnoresOldListAndReleases() {
        let released = WeakReference(nil)
        var retainedOldList: TestList?
        autoreleasepool {
            let source = Fixture()
            let paging = JXPagingSmoothView(dataSource: source)
            released.value = paging
            let window = mount(paging)
            paging.reloadData(); paging.listCollectionView.layoutIfNeeded()
            let old = paging.listDict[0] as! TestList
            retainedOldList = old
            paging.reloadData(); paging.listCollectionView.layoutIfNeeded()
            let current = paging.listDict[0] as! TestList
            XCTAssertFalse(old === current)
            let before = current.scroll.contentOffset
            old.scroll.contentOffset.y = 200
            XCTAssertEqual(current.scroll.contentOffset, before)
            paging.removeFromSuperview(); window.rootViewController = nil
        }
        XCTAssertNil(released.value)
        retainedOldList?.scroll.contentOffset.y = 300
    }
}

@MainActor
private final class Fixture: NSObject, JXPagingViewDelegate, JXPagingSmoothViewDataSource {
    var ids = ["A", "B", "C"]
    var height = 180
    var created = 0
    var controllerLists = false
    let header = UIView()
    let pin = UIView()
    func tableHeaderViewHeight(in pagingView: JXPagingView) -> Int { height }
    func tableHeaderView(in pagingView: JXPagingView) -> UIView { header }
    func heightForPinSectionHeader(in pagingView: JXPagingView) -> Int { 48 }
    func viewForPinSectionHeader(in pagingView: JXPagingView) -> UIView { pin }
    func numberOfLists(in pagingView: JXPagingView) -> Int { ids.count }
    func pagingView(_ pagingView: JXPagingView, listIdentifierAtIndex index: Int) -> String? { ids[index] }
    func pagingView(_ pagingView: JXPagingView, initListAtIndex index: Int) -> any JXPagingViewListViewDelegate {
        created += 1
        return controllerLists ? TestController() : TestList()
    }
    func heightForPagingHeader(in pagingView: JXPagingSmoothView) -> CGFloat { CGFloat(height) }
    func viewForPagingHeader(in pagingView: JXPagingSmoothView) -> UIView { header }
    func heightForPinHeader(in pagingView: JXPagingSmoothView) -> CGFloat { 48 }
    func viewForPinHeader(in pagingView: JXPagingSmoothView) -> UIView { pin }
    func numberOfLists(in pagingView: JXPagingSmoothView) -> Int { ids.count }
    func pagingView(_ pagingView: JXPagingSmoothView, initListAtIndex index: Int) -> any JXPagingSmoothViewListViewDelegate { created += 1; return TestList() }
}
@MainActor
private final class TestList: UIView, JXPagingViewListViewDelegate, JXPagingSmoothViewListViewDelegate, UIScrollViewDelegate {
    let scroll = UIScrollView()
    var callback: (@MainActor (UIScrollView) -> Void)?
    var events: [String] = []
    override init(frame: CGRect) {
        super.init(frame: frame); scroll.delegate = self; addSubview(scroll)
        scroll.contentSize = CGSize(width: 390, height: 3000)
        scroll.contentInsetAdjustmentBehavior = .never
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() { super.layoutSubviews(); scroll.frame = bounds }
    func listView() -> UIView { self }
    func listScrollView() -> UIScrollView { scroll }
    func listViewDidScrollCallback(callback: @escaping @MainActor (UIScrollView) -> Void) { self.callback = callback }
    func scrollViewDidScroll(_ scrollView: UIScrollView) { callback?(scrollView) }
    func listWillAppear() { events.append("willAppear") }
    func listDidAppear() { events.append("didAppear") }
    func listWillDisappear() { events.append("willDisappear") }
    func listDidDisappear() { events.append("didDisappear") }
}
@MainActor
private final class TestController: UIViewController, JXPagingViewListViewDelegate {
    let content = TestList()
    override func loadView() { view = content }
    func listView() -> UIView { view }
    func listScrollView() -> UIScrollView { content.scroll }
    func listViewDidScrollCallback(callback: @escaping @MainActor (UIScrollView) -> Void) { content.callback = callback }
}

@MainActor
private final class WeakReference {
    weak var value: AnyObject?
    init(_ value: AnyObject?) { self.value = value }
}
