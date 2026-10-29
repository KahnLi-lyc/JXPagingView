import UIKit
import JXPagingView

// Public imports only: these witnesses must work across the module boundary.
@MainActor
final class ObjectList: NSObject, JXPagingViewListViewDelegate, JXPagingSmoothViewListViewDelegate {
    private let scrollView = UIScrollView()
    private var didScroll: (@MainActor (UIScrollView) -> Void)?
    func listView() -> UIView { scrollView }
    func listScrollView() -> UIScrollView { scrollView }
    func listViewDidScrollCallback(callback: @escaping @MainActor (UIScrollView) -> Void) { didScroll = callback }
    @objc func listDidAppear() {}
    @objc func listDidDisappear() {}
    func notifyScroll() { didScroll?(scrollView) }
}

@MainActor
final class ControllerList: UIViewController, JXPagingViewListViewDelegate, JXPagingSmoothViewListViewDelegate {
    private let scrollView = UIScrollView()
    private var didScroll: (@MainActor (UIScrollView) -> Void)?
    func listView() -> UIView { view }
    func listScrollView() -> UIScrollView { scrollView }
    func listViewDidScrollCallback(callback: @escaping @MainActor (UIScrollView) -> Void) { didScroll = callback }
    @objc func listDidAppear() {}
    @objc func listDidDisappear() {}
}

@MainActor
final class PagingDelegate: NSObject, JXPagingViewDelegate, JXPagingListContainerViewDataSource,
    JXPagingSmoothViewDataSource, JXPagingSmoothViewDelegate, JXPagingMainTableViewGestureDelegate {
    func tableHeaderViewHeight(in pagingView: JXPagingView) -> Int { 120 }
    func tableHeaderView(in pagingView: JXPagingView) -> UIView { UIView() }
    func heightForPinSectionHeader(in pagingView: JXPagingView) -> Int { 44 }
    func viewForPinSectionHeader(in pagingView: JXPagingView) -> UIView { UIView() }
    func numberOfLists(in pagingView: JXPagingView) -> Int { 2 }
    func pagingView(_ pagingView: JXPagingView, initListAtIndex index: Int) -> JXPagingViewListViewDelegate {
        index == 0 ? ObjectList() : ControllerList()
    }
    func numberOfLists(in listContainerView: JXPagingListContainerView) -> Int { 2 }
    func listContainerView(_ listContainerView: JXPagingListContainerView, initListAt index: Int) -> JXPagingViewListViewDelegate {
        index == 0 ? ObjectList() : ControllerList()
    }
    func heightForPagingHeader(in pagingView: JXPagingSmoothView) -> CGFloat { 120 }
    func viewForPagingHeader(in pagingView: JXPagingSmoothView) -> UIView { UIView() }
    func heightForPinHeader(in pagingView: JXPagingSmoothView) -> CGFloat { 44 }
    func viewForPinHeader(in pagingView: JXPagingSmoothView) -> UIView { UIView() }
    func numberOfLists(in pagingView: JXPagingSmoothView) -> Int { 2 }
    func pagingView(_ pagingView: JXPagingSmoothView, initListAtIndex index: Int) -> JXPagingSmoothViewListViewDelegate {
        index == 0 ? ObjectList() : ControllerList()
    }
    func pagingSmoothViewDidScroll(_ scrollView: UIScrollView) { _ = scrollView.contentOffset }
    func mainTableViewGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { false }
}

@MainActor
final class CustomPagingView: JXPagingView {
    override func preferredProcessMainTableViewDidScroll(_ scrollView: UIScrollView) {
        super.preferredProcessMainTableViewDidScroll(scrollView)
    }
}

@MainActor
final class CustomRefreshView: JXPagingListRefreshView {}

@MainActor
final class CustomSmoothView: JXPagingSmoothView {
    override func layoutSubviews() { super.layoutSubviews() }
}

@MainActor
final class CustomContainerView: JXPagingListContainerView {
    override func commonInit() { super.commonInit() }
}

@MainActor
final class CustomMainTableView: JXPagingMainTableView {}

@MainActor
public func makeConsumerViews() -> [UIView] {
    let delegate = PagingDelegate()
    let paging = CustomPagingView(delegate: delegate)
    let smooth = CustomSmoothView(dataSource: delegate)
    smooth.delegate = delegate
    paging.mainTableView.gestureDelegate = delegate
    let container = CustomContainerView(dataSource: delegate)
    return [paging, smooth, container, CustomRefreshView(delegate: delegate), CustomMainTableView()]
}
