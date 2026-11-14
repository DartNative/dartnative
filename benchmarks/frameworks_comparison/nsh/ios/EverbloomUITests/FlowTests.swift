// Walks the app's flows on the simulator with the benchmark's identifiers.
// Development check only: `xcodebuild test` (see BUILD.md).

import XCTest

final class FlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        if let url = ProcessInfo.processInfo.environment["SHOP_API_URL"], !url.isEmpty {
            app.launchEnvironment["SHOP_API_URL"] = url
        }
        app.launch()
    }

    private func el(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    @discardableResult
    private func wait(_ id: String, _ timeout: TimeInterval = 20) -> XCUIElement {
        let e = el(id)
        XCTAssertTrue(e.waitForExistence(timeout: timeout), "missing \(id)\n\(app.debugDescription)")
        return e
    }

    private func gone(_ id: String, _ timeout: TimeInterval = 10) {
        let p = NSPredicate(format: "exists == false")
        let x = expectation(for: p, evaluatedWith: el(id))
        wait(for: [x], timeout: timeout)
    }

    private func dump(_ name: String) {
        let a = XCTAttachment(string: app.debugDescription)
        a.name = name
        a.lifetime = .keepAlways
        add(a)
        print("=== \(name)\n\(app.debugDescription)")
    }

    func testHomeIdentifiers() {
        wait("home-scroll")
        for id in ["tab-home", "tab-search", "tab-cart", "collection-chip-0", "featured-collection",
                   "collection-card-0", "best-seller-0"] {
            wait(id)
        }
        dump("home")
    }

    func testCollectionScrollsToEndAndSorts() {
        wait("collection-chip-0").tap()
        let grid = wait("product-grid")
        wait("product-card-0")
        for id in ["back", "sort-featured", "sort-best-selling", "sort-price-asc", "sort-price-desc"] {
            wait(id)
        }
        dump("collection")
        // Scroll until the last card stops changing.
        var last = ""
        var stable = 0
        for _ in 0..<60 where stable < 3 {
            grid.swipeUp(velocity: .fast)
            let cards = app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier BEGINSWITH 'product-card-'"))
                .allElementsBoundByIndex.map(\.identifier)
            let maxCard = cards.compactMap { Int($0.split(separator: "-").last ?? "") }.max() ?? 0
            let key = "\(maxCard)"
            stable = (key == last) ? stable + 1 : 0
            last = key
        }
        print("=== last card index \(last)")
        XCTAssertGreaterThan(Int(last) ?? 0, 23, "a second page loaded")
        for sort in ["sort-best-selling", "sort-price-asc", "sort-price-desc", "sort-featured"] {
            el(sort).tap()
            wait("product-card-0")
        }
        el("back").tap()
        wait("home-scroll")
    }

    func testProductOptionsRecommendationsCart() {
        wait("best-seller-0").tap()
        wait("product-carousel")
        let add = wait("add-to-cart")
        XCTAssertFalse(el("tab-home").exists, "tab bar hidden on product")
        dump("product")
        let options = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'option-'"))
        if options.count > 1 {
            let before = add.label
            options.element(boundBy: options.count - 1).tap()
            print("=== price \(before) -> \(add.label)")
        }
        el("product-carousel").swipeLeft()
        // A recommendation opens another product.
        let scroll = app.scrollViews.firstMatch
        for _ in 0..<4 where !el("recommendation-0").isHittable { scroll.swipeUp() }
        wait("recommendation-0").tap()
        wait("add-to-cart")
        dump("recommended product")
        el("back").firstMatch.tap()
        wait("add-to-cart").tap()
        // Switched to Cart with the badge.
        wait("cart-line-0")
        XCTAssertEqual(wait("cart-badge").label, "1")
        let subtotal = wait("cart-subtotal").label
        dump("cart")
        wait("qty-inc-0").tap()
        let p = NSPredicate(format: "label != %@", subtotal)
        wait(for: [expectation(for: p, evaluatedWith: el("cart-subtotal"))], timeout: 15)
        XCTAssertEqual(el("cart-badge").label, "2")
        wait("qty-dec-0").tap()
        wait(for: [expectation(for: NSPredicate(format: "label == %@", subtotal), evaluatedWith: el("cart-subtotal"))], timeout: 15)
        sleep(1)
        wait("qty-dec-0").tap()
        gone("cart-line-0", 15)
        XCTAssertTrue(app.staticTexts["Your cart is empty"].waitForExistence(timeout: 5))
        XCTAssertFalse(el("cart-badge").exists)
    }

    func testCheckout() {
        wait("best-seller-1").tap()
        wait("add-to-cart").tap()
        wait("checkout").tap()
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 15))
    }

    func testSearch() {
        wait("tab-search").tap()
        let field = wait("search-input")
        XCTAssertTrue(app.staticTexts["Search across 995 products by name."].exists)
        field.tap()
        field.typeText("shirt")
        let results = wait("search-results")
        wait("search-result-0")
        dump("search")
        field.typeText("\n")
        for _ in 0..<8 { results.swipeUp(velocity: .fast) }
        dump("search scrolled")
        let rows = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'search-result-'"))
            .allElementsBoundByIndex.map(\.identifier)
        print("=== search rows \(rows)")
        XCTAssertGreaterThan(rows.count, 3)
        let middle = rows.sorted { (Int($0.split(separator: "-").last!) ?? 0) < (Int($1.split(separator: "-").last!) ?? 0) }[rows.count / 2]
        print("=== tapping \(middle)")
        el(middle).tap()
        wait("add-to-cart")
        el("back").tap()
        wait("search-results")
    }
}

final class KeyboardScrollTests: XCTestCase {
    func testResultsScrollWithKeyboardUp() {
        let app = XCUIApplication()
        app.launch()
        let any = app.descendants(matching: .any)
        any.matching(identifier: "tab-search").firstMatch.tap()
        let field = any.matching(identifier: "search-input").firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("shirt")
        let results = any.matching(identifier: "search-results").firstMatch
        XCTAssertTrue(any.matching(identifier: "search-result-0").firstMatch.waitForExistence(timeout: 20))
        print("=== keyboard up: \(app.keyboards.count)")
        results.swipeUp()
        sleep(1)
        print("=== keyboard after swipe: \(app.keyboards.count)")
        results.swipeUp()
        results.swipeUp()
        sleep(1)
        let rows = any.matching(NSPredicate(format: "identifier BEGINSWITH 'search-result-'"))
            .allElementsBoundByIndex.filter { $0.isHittable }.map(\.identifier)
        print("=== hittable rows \(rows)")
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.lifetime = .keepAlways
        add(shot)
        XCTAssertFalse(rows.contains("search-result-0"))
        any.matching(identifier: rows[1]).firstMatch.tap()
        XCTAssertTrue(any.matching(identifier: "add-to-cart").firstMatch.waitForExistence(timeout: 15))
    }
}

final class ErrorStateTests: XCTestCase {
    /// SHOP_API_URL points at a server that starts while the error shows.
    func testRetryAfterFailure() {
        let app = XCUIApplication()
        app.launchEnvironment["SHOP_API_URL"] = ProcessInfo.processInfo.environment["SHOP_API_URL"] ?? "http://127.0.0.1:8787/api"
        app.launch()
        let any = app.descendants(matching: .any)
        let retry = any.matching(identifier: "error-retry").firstMatch
        XCTAssertTrue(retry.waitForExistence(timeout: 30), app.debugDescription)
        XCTAssertTrue(app.staticTexts["Couldn't load products"].exists)
        print("=== error shown")
        sleep(10)
        retry.tap()
        XCTAssertTrue(any.matching(identifier: "best-seller-0").firstMatch.waitForExistence(timeout: 30))
        XCTAssertTrue(any.matching(identifier: "collection-chip-0").firstMatch.exists)
    }
}

final class ScreenshotTests: XCTestCase {
    /// Writes each screen to SHOTS_DIR (development aid).
    func testScreens() throws {
        guard let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] else { throw XCTSkip("no SHOTS_DIR") }
        let app = XCUIApplication()
        app.launch()
        let any = app.descendants(matching: .any)
        func el(_ id: String) -> XCUIElement { any.matching(identifier: id).firstMatch }
        func shot(_ name: String) {
            sleep(2)
            try? app.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
        }
        XCTAssertTrue(el("best-seller-0").waitForExistence(timeout: 20))
        shot("1-home")
        el("home-scroll").swipeUp()
        shot("2-home-scrolled")
        el("home-scroll").swipeDown()
        el("collection-chip-0").tap()
        XCTAssertTrue(el("product-card-0").waitForExistence(timeout: 20))
        shot("3-collection")
        el("sort-price-desc").tap()
        XCTAssertTrue(el("product-card-0").waitForExistence(timeout: 20))
        shot("4-collection-sorted")
        el("product-card-0").tap()
        XCTAssertTrue(el("add-to-cart").waitForExistence(timeout: 20))
        shot("5-product")
        app.scrollViews.firstMatch.swipeUp()
        shot("6-product-scrolled")
        el("add-to-cart").tap()
        XCTAssertTrue(el("cart-line-0").waitForExistence(timeout: 20))
        shot("7-cart")
        el("tab-search").tap()
        shot("8-search-empty")
        el("search-input").tap()
        el("search-input").typeText("linen")
        XCTAssertTrue(el("search-result-0").waitForExistence(timeout: 20))
        shot("9-search")
        el("search-input").typeText("\n")
        el("tab-cart").tap()
        el("qty-dec-0").tap()
        XCTAssertTrue(app.staticTexts["Your cart is empty"].waitForExistence(timeout: 20))
        shot("10-cart-empty")
    }
}
