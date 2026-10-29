import XCTest
import UIKit
@testable import JXPagingView

@MainActor
final class PackageRegressionTests: XCTestCase {
    func testPrivacyManifestIsInSwiftPackageBundle() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let plist = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: Any]
        XCTAssertEqual(plist?["NSPrivacyTracking"] as? Bool, false)
    }

    func testListContainerKeepsLogicalIndicesWithForcedRTLParent() {
        for type in [JXPagingListContainerType.scrollView, .collectionView] {
            let source = Lists()
            let parent = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
            parent.semanticContentAttribute = .forceRightToLeft
            let container = JXPagingListContainerView(dataSource: source, type: type)
            parent.addSubview(container)
            container.frame = parent.bounds
            container.reloadData()
            container.layoutIfNeeded()
            container.didClickSelectedItem(at: 1)
            XCTAssertEqual(container.currentIndex, 1)
            XCTAssertNotNil(container.validListDict[1])
            XCTAssertEqual(container.contentScrollView().bounds.width, 320)
        }
    }
}

private final class Lists: NSObject, JXPagingListContainerViewDataSource {
    func numberOfLists(in listContainerView: JXPagingListContainerView) -> Int { 2 }
    func listContainerView(_ listContainerView: JXPagingListContainerView, initListAt index: Int) -> JXPagingViewListViewDelegate { List() }
}
private final class List: NSObject, JXPagingViewListViewDelegate {
    let view = UIScrollView()
    func listView() -> UIView { view }
    func listScrollView() -> UIScrollView { view }
    func listViewDidScrollCallback(callback: @escaping @MainActor (UIScrollView) -> ()) {}
}
