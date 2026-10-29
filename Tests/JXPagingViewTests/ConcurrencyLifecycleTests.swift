import XCTest
import UIKit
@testable import JXPagingView

@MainActor
final class ConcurrencyLifecycleTests: XCTestCase {
    private func mount(_ view: UIView) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 600))
        let controller = UIViewController()
        window.rootViewController = controller
        window.makeKeyAndVisible()
        view.frame = controller.view.bounds
        controller.view.addSubview(view)
        controller.view.layoutIfNeeded()
        view.layoutIfNeeded()
        return window
    }

    func testSmoothObservationIsSynchronousAndRemovedOnReload() throws {
        let source = SmoothSource()
        let paging = ObservedSmoothView(dataSource: source)
        let window = mount(paging)
        defer { window.isHidden = true }
        paging.reloadData()
        paging.listCollectionView.layoutIfNeeded()
        let old = try XCTUnwrap(paging.listDict[0] as? SmoothList)
        let notifications = paging.offsetNotifications
        old.scroll.contentOffset.y = -100
        XCTAssertEqual(paging.offsetNotifications, notifications + 1)
        XCTAssertEqual(paging.lastChangeKind, NSKeyValueChange.setting.rawValue)
        XCTAssertEqual(paging.lastOffset, CGPoint(x: 0, y: -100))
        XCTAssertTrue(paging.currentListScrollView === old.scroll)
        XCTAssertEqual(paging.currentPagingHeaderContainerViewY, -144)
        old.scroll.contentSize.height = 1
        XCTAssertGreaterThanOrEqual(old.scroll.contentSize.height, paging.bounds.height - 44)
        paging.reloadData()
        paging.listCollectionView.layoutIfNeeded()
        let replacement = try XCTUnwrap(paging.listDict[0] as? SmoothList)
        XCTAssertFalse(old === replacement)
        replacement.scroll.contentOffset.y = -120
        let current = paging.currentListScrollView
        old.scroll.contentOffset.y = 200
        old.scroll.contentSize.height = 1
        XCTAssertTrue(paging.currentListScrollView === current)
        XCTAssertEqual(old.scroll.contentSize.height, 1)
        for _ in 0..<3 { paging.reloadData(); paging.listCollectionView.layoutIfNeeded() }
    }

    func testSmoothReleaseInvalidatesObservationWhileListSurvives() throws {
        let source = SmoothSource()
        weak var weakPaging: JXPagingSmoothView?
        var list: SmoothList?
        try autoreleasepool {
            let paging = JXPagingSmoothView(dataSource: source)
            weakPaging = paging
            let window = mount(paging)
            paging.reloadData()
            paging.listCollectionView.layoutIfNeeded()
            list = try XCTUnwrap(paging.listDict[0] as? SmoothList)
            paging.removeFromSuperview()
            window.isHidden = true
            window.rootViewController = nil
        }
        XCTAssertNil(weakPaging)
        list?.scroll.contentOffset.y = 50
        list?.scroll.contentSize.height = 1
        XCTAssertEqual(list?.scroll.contentSize.height, 1)
    }

    func testOldScrollCallbackCannotReplaceReloadedList() {
        let source = PagingSource()
        let paging = JXPagingView(delegate: source, listContainerType: .scrollView)
        let old = paging.listContainerView(paging.listContainerView, initListAt: 0) as! PagingList
        paging.reloadData()
        let replacement = paging.listContainerView(paging.listContainerView, initListAt: 0) as! PagingList
        replacement.onScroll?(replacement.scroll)
        old.onScroll?(old.scroll)
        XCTAssertTrue(paging.currentList === replacement)
        XCTAssertTrue(paging.currentScrollingListView === replacement.scroll)
    }

    func testPagingCoordinatesPinningAndHeaderResizeForBothContainers() {
        for type in [JXPagingListContainerType.scrollView, .collectionView] {
            let source = PagingSource()
            let paging = JXPagingView(delegate: source, listContainerType: type)
            let window = mount(paging)
            defer { window.isHidden = true }
            paging.reloadData()
            paging.layoutIfNeeded()
            let list = paging.listContainerView(paging.listContainerView, initListAt: 0) as! PagingList
            list.onScroll?(list.scroll)
            XCTAssertTrue(paging.currentList === list)
            XCTAssertTrue(paging.currentScrollingListView === list.scroll)
            paging.mainTableView.contentOffset.y = 0
            list.scroll.contentOffset.y = 30
            paging.preferredProcessListViewDidScroll(scrollView: list.scroll)
            XCTAssertEqual(list.scroll.contentOffset.y, 0)
            paging.mainTableView.contentOffset.y = 200
            paging.preferredProcessListViewDidScroll(scrollView: list.scroll)
            XCTAssertEqual(paging.mainTableView.contentOffset.y, 200)
            source.height = 300
            paging.resizeTableHeaderViewHeight()
            XCTAssertEqual(paging.mainTableView.tableHeaderView?.bounds.height, 300)
            XCTAssertEqual(paging.mainTableViewMaxContentOffsetY(), 300)
        }
    }

    func testListContainerIsLazyAndReleases() {
        let source = PagingSource()
        weak var weakPaging: JXPagingView?
        autoreleasepool {
            let paging = JXPagingView(delegate: source, listContainerType: .scrollView)
            weakPaging = paging
            let window = mount(paging)
            paging.reloadData()
            paging.listContainerView.layoutIfNeeded()
            XCTAssertNotNil(paging.listContainerView.validListDict[0])
            XCTAssertNil(paging.listContainerView.validListDict[2])
            paging.listContainerView.didClickSelectedItem(at: 2)
            XCTAssertNotNil(paging.listContainerView.validListDict[2])
            XCTAssertEqual(paging.listContainerView.currentIndex, 2)
            paging.removeFromSuperview()
            window.isHidden = true
            window.rootViewController = nil
        }
        XCTAssertNil(weakPaging)
    }

}

@MainActor
private final class SmoothList: NSObject, JXPagingSmoothViewListViewDelegate {
    let scroll = UIScrollView()
    func listView() -> UIView { scroll }
    func listScrollView() -> UIScrollView { scroll }
}

@MainActor
private final class SmoothSource: NSObject, JXPagingSmoothViewDataSource {
    func heightForPagingHeader(in pagingView: JXPagingSmoothView) -> CGFloat { 200 }
    func viewForPagingHeader(in pagingView: JXPagingSmoothView) -> UIView { UIView() }
    func heightForPinHeader(in pagingView: JXPagingSmoothView) -> CGFloat { 44 }
    func viewForPinHeader(in pagingView: JXPagingSmoothView) -> UIView { UIView() }
    func numberOfLists(in pagingView: JXPagingSmoothView) -> Int { 3 }
    func pagingView(_ pagingView: JXPagingSmoothView, initListAtIndex index: Int) -> JXPagingSmoothViewListViewDelegate { SmoothList() }
}

@MainActor
private final class PagingList: NSObject, JXPagingViewListViewDelegate {
    let scroll = UIScrollView()
    var onScroll: (@MainActor (UIScrollView) -> Void)?
    func listView() -> UIView { scroll }
    func listScrollView() -> UIScrollView { scroll }
    func listViewDidScrollCallback(callback: @escaping @MainActor (UIScrollView) -> Void) { onScroll = callback }
}

@MainActor
private final class PagingSource: NSObject, JXPagingViewDelegate {
    var height = 200
    func tableHeaderViewHeight(in pagingView: JXPagingView) -> Int { height }
    func tableHeaderView(in pagingView: JXPagingView) -> UIView { UIView() }
    func heightForPinSectionHeader(in pagingView: JXPagingView) -> Int { 44 }
    func viewForPinSectionHeader(in pagingView: JXPagingView) -> UIView { UIView() }
    func numberOfLists(in pagingView: JXPagingView) -> Int { 3 }
    func pagingView(_ pagingView: JXPagingView, initListAtIndex index: Int) -> JXPagingViewListViewDelegate { PagingList() }
}

private final class ObservedSmoothView: JXPagingSmoothView {
    var offsetNotifications = 0
    var lastChangeKind: UInt?
    var lastOffset: CGPoint?
    nonisolated override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        precondition(Thread.isMainThread)
        let kind = change?[.kindKey] as? UInt
        let offset = change?[.newKey] as? CGPoint
        MainActor.assumeIsolated {
            if keyPath == "contentOffset" {
                offsetNotifications += 1
                lastChangeKind = kind
                lastOffset = offset
            }
        }
        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
}
