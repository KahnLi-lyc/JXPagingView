import XCTest

@MainActor
final class DemoUITests: XCTestCase {
    var app: XCUIApplication!
    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication(); app.launch()
    }
    private func open(_ route: String) {
        let cell = app.cells["route.\(route)"]
        if !cell.isHittable { app.tables["catalog"].swipeUp() }
        XCTAssertTrue(cell.waitForExistence(timeout: 5)); cell.tap()
        XCTAssertTrue(app.staticTexts["snapshot"].waitForExistence(timeout: 5))
    }
    private func expect(_ fragment: String, timeout: TimeInterval = 5) {
        let predicate = NSPredicate(format: "label CONTAINS %@", fragment)
        expectation(for: predicate, evaluatedWith: app.staticTexts["snapshot"])
        waitForExpectations(timeout: timeout)
    }
    private func back() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.tables["catalog"].waitForExistence(timeout: 5))
    }
    func testEveryCatalogEntrySelectsRealPageAndReleases() {
        for route in ["scroll", "collection", "refresh", "smooth", "header", "cache", "controllers", "gestures", "nested", "container"] {
            open(route)
            expect("selected=\(route == "collection" ? 1 : 0)")
            app.buttons["next"].tap()
            expect("selected=\(route == "collection" ? 2 : 1)")
            expect("visible=\(route == "collection" ? "Gamma" : "Beta")")
            app.buttons["reload"].tap()
            expect("count=3")
            back()
            let predicate = NSPredicate(format: "label CONTAINS %@", "Released scene: true; live lists: 0")
            expectation(for: predicate, evaluatedWith: app.staticTexts["release"])
            waitForExpectations(timeout: 5)
        }
    }
    func testHeaderEmptyRestoreAndCacheIdentity() {
        open("cache")
        expect("Alpha#1")
        app.buttons["reload"].tap(); expect("Alpha#1")
        app.buttons["header"].tap(); expect("header=260")
        app.buttons["pin"].tap(); expect("offset=260")
        app.buttons["data"].tap(); expect("count=0")
        app.buttons["data"].tap(); expect("count=3"); expect("Gamma")
        app.buttons["data"].tap(); expect("count=4")
        app.buttons["data"].tap(); expect("count=2")
    }
    func testDataChangesResetPhysicalAndLogicalPageFromNonzeroSelection() {
        for route in ["scroll", "collection", "smooth", "container"] {
            open(route)
            app.buttons["data"].tap(); expect("count=0")
            app.buttons["data"].tap(); expect("count=3")
            app.buttons["next"].tap(); expect("selected=1"); expect("visible=Beta")
            app.buttons["data"].tap(); expect("count=4"); expect("selected=0"); expect("visible=Gamma")
            back()
        }
    }
    func testRefreshSurvivesSwitchAndEnds() {
        open("refresh")
        app.buttons["refresh"].tap(); expect("refreshing=true")
        app.buttons["next"].tap(); expect("selected=1")
        expect("refreshing=true")
        expect("refreshing=false", timeout: 8)
    }
    func testSwipeAndRotationOnPhoneAndPad() {
        open("scroll")
        app.otherElements["paging.host"].swipeLeft()
        expect("selected=1")
        XCUIDevice.shared.orientation = .landscapeLeft
        expect("selected=1")
        app.buttons["next"].tap(); expect("selected=2")
        XCUIDevice.shared.orientation = .portrait
    }
    func testCreationGateAndNestedHorizontalContent() {
        open("container")
        app.buttons["options"].tap()
        app.buttons["Toggle creation gate for page Beta"].tap()
        app.buttons["next"].tap()
        expect("selected=1"); expect("visible=none")
        app.buttons["options"].tap()
        app.buttons["Toggle creation gate for page Beta"].tap()
        expect("visible=Beta")
        back()
        open("nested")
        app.scrollViews["nested"].firstMatch.swipeLeft()
        expect("selected=0"); expect("visible=Alpha"); expect("nestedMoved=true")
    }
    func testEnvironmentAndEdgeReturn() {
        app.navigationBars.buttons["Environment"].tap()
        app.buttons["Toggle RTL"].tap()
        app.navigationBars.buttons["Environment"].tap()
        app.buttons["Toggle dark / light"].tap()
        app.navigationBars.buttons["Environment"].tap()
        app.buttons["Toggle reduced motion"].tap()
        open("header")
        app.buttons["pin"].tap(); expect("pinY=20")
        app.buttons["header"].tap(); expect("header=260")
        back()
        open("gestures")
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)))
        XCTAssertTrue(app.tables["catalog"].waitForExistence(timeout: 5))
    }
    func testSmoothHeaderAndContentResize() {
        open("smooth")
        app.buttons["pin"].tap()
        app.buttons["next"].tap(); expect("selected=1")
        app.buttons["header"].tap(); expect("header=260"); expect("selected=1")
        app.buttons["reload"].tap(); expect("selected=1")
        app.buttons["data"].tap(); expect("count=0")
        app.buttons["data"].tap(); expect("count=3")
        app.buttons["next"].tap(); expect("selected=1")
        app.buttons["data"].tap(); expect("count=4"); expect("selected=0"); expect("visible=Gamma")
    }
}
