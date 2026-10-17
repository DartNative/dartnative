import XCTest

/// Scrolls one benchmark app the same way for every app and lets XCTest
/// measure it with Apple's scroll metric (hitch time ratio, frame rate),
/// which UIKit reports for any UIScrollView, whatever builds the content.
/// CPU and memory are not measured here: a metric over the whole block
/// would count the work XCTest itself causes between swipes (its
/// accessibility snapshots make a UITableView create cells), so they come
/// from an Instruments trace read inside the scroll intervals (trace.sh).
///
/// Settings come from the environment (run.sh sets them with the
/// TEST_RUNNER_ prefix xcodebuild strips):
///   BENCH_BUNDLE      the app's bundle id
///   BENCH_URL         a URL to open the screen with (the React Native app), optional
///   BENCH_SWIPES      swipes per iteration (default 25)
///   BENCH_ITERATIONS  measured iterations (default 5)
///   BENCH_SCROLL_TARGETS testScrollTo only: the targets, as testScrollTo says
///   BENCH_DIRECTION   "both" to swipe back down for as many swipes afterwards,
///                     "down" to swipe down only (the Chat screen, which opens
///                     at its newest message and is scrolled up through its
///                     history)
///   BENCH_SHOT_SWIPES testScreenshot only: slow swipes, in BENCH_DIRECTION,
///                     before the screenshot, to show a part of the list
///                     other than its start (default 0)
///   BENCH_SPEED       testFlicks only: the finger's speed at release, in
///                     points a second (default 4,000)
///   BENCH_PAUSE       testFlicks only: seconds between flicks (default 2.5,
///                     which lets the list settle; 0.3 is a finger that keeps
///                     flicking while the list still moves)
final class ScrollBenchmarkTests: XCTestCase {
    private var env: [String: String] { ProcessInfo.processInfo.environment }

    /// Answers the alert iOS shows when a Mac starts recording the
    /// iPhone's screen and sound over the cable ("Are you connecting a pair
    /// of headphones?"): the Mac is another device, not headphones.
    private func answerRecordingAlert() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let button = springboard.buttons["Other Device"]
        if button.waitForExistence(timeout: 1) { button.tap() }
    }

    /// Keeps a screenshot of whatever the phone shows, as it is: the screen
    /// an app was left on after a driven run, without opening anything.
    func testScreenAsIs() throws {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "screen"
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// Opens the screen and keeps a screenshot in the result bundle, for the
    /// side-by-side check that the apps draw the same screen.
    func testScreenshot() throws {
        let bundle = try XCTUnwrap(env["BENCH_BUNDLE"], "set BENCH_BUNDLE")
        let app = XCUIApplication(bundleIdentifier: bundle)
        answerRecordingAlert()
        app.terminate()
        if let url = env["BENCH_URL"].flatMap(URL.init(string:)) {
            app.open(url)
        } else {
            app.launch()
        }
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))
        sleep(6)
        let swipes = Int(env["BENCH_SHOT_SWIPES"] ?? "") ?? 0
        for _ in 0..<swipes {
            if env["BENCH_DIRECTION"] == "down" { app.swipeDown(velocity: .slow) } else { app.swipeUp(velocity: .slow) }
        }
        if swipes > 0 { sleep(3) }
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = bundle
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testScroll() throws {
        let bundle = try XCTUnwrap(env["BENCH_BUNDLE"], "set BENCH_BUNDLE")
        let swipes = Int(env["BENCH_SWIPES"] ?? "") ?? 25
        let iterations = Int(env["BENCH_ITERATIONS"] ?? "") ?? 5
        let both = env["BENCH_DIRECTION"] == "both"
        let down = env["BENCH_DIRECTION"] == "down"
        let app = XCUIApplication(bundleIdentifier: bundle)
        answerRecordingAlert()

        let options = XCTMeasureOptions()
        options.iterationCount = iterations
        options.invocationOptions = [.manuallyStart, .manuallyStop]

        measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric], options: options) {
            // Every iteration starts from a fresh launch at the top of the
            // list, or at the newest message of the chat.
            app.terminate()
            if let url = env["BENCH_URL"].flatMap(URL.init(string:)) {
                app.open(url)
            } else {
                app.launch()
            }
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))
            sleep(5)
            startMeasuring()
            for _ in 0..<swipes {
                if down { app.swipeDown(velocity: .fast) } else { app.swipeUp(velocity: .fast) }
            }
            if both {
                sleep(1)
                for _ in 0..<swipes {
                    app.swipeDown(velocity: .fast)
                }
            }
            sleep(2)
            stopMeasuring()
        }
    }

    /// Flicks the list with real touches, for the blank count. The app is
    /// launched in the driver's watch mode (BENCH_WATCH,
    /// autoscroll/BenchAutoScroll.m), which counts blank rows in every frame
    /// the list moves and writes the count once a second; the test only
    /// flicks. Each flick drags the middle of the screen over half its
    /// height at BENCH_SPEED points a second and lets go, in BENCH_DIRECTION
    /// ("down" for the Chat screen), one every BENCH_PAUSE seconds. XCTest
    /// measures nothing here: its accessibility snapshots around each
    /// gesture make a UITableView build every row, so the timed runs use
    /// the driver's flings (trace.sh). This is the one run that needs real
    /// touches, since a list that prepares its rows on another thread can
    /// keep up with the driver's flings and still fall behind a finger's.
    func testFlicks() throws {
        let bundle = try XCTUnwrap(env["BENCH_BUNDLE"], "set BENCH_BUNDLE")
        let swipes = Int(env["BENCH_SWIPES"] ?? "") ?? 25
        let down = env["BENCH_DIRECTION"] == "down"
        let speed = CGFloat(Double(env["BENCH_SPEED"] ?? "") ?? 4000)
        let pause = Double(env["BENCH_PAUSE"] ?? "") ?? 2.5
        let app = XCUIApplication(bundleIdentifier: bundle)
        answerRecordingAlert()
        app.terminate()
        app.launchEnvironment = ["BENCH_WATCH": "1"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))
        // The driver looks for the list eight seconds after launch.
        sleep(10)
        let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: down ? 0.3 : 0.8))
        let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: down ? 0.8 : 0.3))
        for _ in 0..<swipes {
            from.press(forDuration: 0.01, thenDragTo: to, withVelocity: XCUIGestureVelocity(rawValue: speed), thenHoldForDuration: 0)
            Thread.sleep(forTimeInterval: pause)
        }
        sleep(3)
    }

    /// The scroll-to test: taps the bar's Scroll button once per target
    /// (BENCH_SCROLL_TARGETS, ";" between them, in the order of the apps'
    /// scroll targets) and, once the screen stops moving, reads where the
    /// target's top rests. On the Chat screen a target is "time|sender", and
    /// its top is the top of the sender's name (the bubble's first line)
    /// nearest above the message's time and starting where the time starts;
    /// no two messages share a time. On the Cards screen a target is the
    /// card's title, such as "Item #400", and its top is the title's. The
    /// readings, in points from the screen's top, go to the result bundle
    /// as "scroll-results"; scroll_to.sh turns them into landing errors.
    func testScrollTo() throws {
        let bundle = try XCTUnwrap(env["BENCH_BUNDLE"], "set BENCH_BUNDLE")
        let targets = try XCTUnwrap(env["BENCH_SCROLL_TARGETS"], "set BENCH_SCROLL_TARGETS")
            .split(separator: ";").map { $0.split(separator: "|").map(String.init) }
        let button = "Scroll"
        let app = XCUIApplication(bundleIdentifier: bundle)
        answerRecordingAlert()
        app.terminate()
        if let url = env["BENCH_URL"].flatMap(URL.init(string:)) {
            app.open(url)
        } else {
            app.launch()
        }
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))
        sleep(8)
        var lines: [String] = []
        var titleBelowAuthor: CGFloat?
        for (n, target) in targets.enumerated() {
            let scroll = app.buttons[button].firstMatch
            XCTAssertTrue(scroll.waitForExistence(timeout: 5), "no \(button) button on screen")
            scroll.tap()
            let start = Date()
            sleep(2)
            var texts = try labelled(app)
            var settled = false
            while Date().timeIntervalSince(start) < 45 {
                sleep(1)
                let now = try labelled(app)
                if now.map({ "\($0.0)@\($0.1.minY)" }) == texts.map({ "\($0.0)@\($0.1.minY)" }) {
                    settled = true
                    break
                }
                texts = now
            }
            // Only what is on screen counts: a table can keep a cell laid out
            // far outside its bounds, and a target there is a miss.
            let screen = app.frame
            let shown = texts.filter { $0.1.intersects(screen) }
            var top = target.count == 2
                ? messageTop(shown.filter { $0.2 }.map { ($0.0, $0.1) }, time: target[0], sender: target[1])
                : itemTop(shown, target[0])
            // A card that stops so low that its title is below the screen is
            // placed from its author line, using the gap between the author
            // line and the title measured on the first card.
            if target.count == 1, let author = authorTop(shown, target[0]) {
                if n == 0, let title = top {
                    titleBelowAuthor = title - author
                } else if top == nil, let offset = titleBelowAuthor {
                    top = author + offset
                }
            }
            if n == 0 {
                // On the first target, keep every text the test can read, to
                // check that an app exposes its texts as the test expects.
                var dump: [String] = []
                func walk(_ e: XCUIElementSnapshot) {
                    if !e.label.isEmpty { dump.append("\(e.elementType.rawValue)\t\(e.label)\t\(e.frame)") }
                    e.children.forEach(walk)
                }
                walk(try app.snapshot())
                let tree = XCTAttachment(string: dump.joined(separator: "\n"))
                tree.name = "scroll-tree"
                tree.lifetime = .keepAlways
                add(tree)
            }
            lines.append("\(n)\t\(target[0])\t\(top.map { String(format: "%.1f", $0) } ?? "none")"
                + "\t\(settled ? String(format: "%.1f", Date().timeIntervalSince(start)) : "none")")
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "scroll\(n)"
            shot.lifetime = .keepAlways
            add(shot)
        }
        let report = XCTAttachment(string: lines.joined(separator: "\n"))
        report.name = "scroll-results"
        report.lifetime = .keepAlways
        add(report)
    }

    /// Every element on screen with a label, its frame and whether it is a
    /// static text, from one snapshot of the app's accessibility tree. React
    /// Native exposes each text twice, as two elements with the same label
    /// and frame; they count once. A React Native view that responds to
    /// touch, as a card does, is one element whose label joins the texts
    /// inside it ("Jordan Lee 1, 1h ago, Item #1, ..."), with no texts of
    /// its own; the screen has settled when every label stays put.
    private func labelled(_ app: XCUIApplication) throws -> [(String, CGRect, Bool)] {
        var out: [(String, CGRect, Bool)] = []
        var seen = Set<String>()
        func walk(_ e: XCUIElementSnapshot) {
            if !e.label.isEmpty, seen.insert("\(e.label)@\(e.frame)").inserted {
                out.append((e.label, e.frame, e.elementType == .staticText))
            }
            e.children.forEach(walk)
        }
        walk(try app.snapshot())
        return out
    }

    /// Where the item named [label] rests: the top of its own text, or, in an
    /// app whose card is one element, the top of the element whose label
    /// joins that name with the card's other texts. The landing error is
    /// measured against the first landing of the same app, read the same
    /// way.
    private func itemTop(_ elements: [(String, CGRect, Bool)], _ label: String) -> CGFloat? {
        let texts = elements.filter { $0.2 && $0.0 == label }
        if texts.count == 1 { return texts[0].1.minY }
        let joined = elements.filter { $0.0.components(separatedBy: ", ").contains(label) }
        return joined.count == 1 ? joined[0].1.minY : nil
    }

    /// The top of the author line ("Alex Thompson 400") of the card titled
    /// [label] ("Item #400"), the line above its title, where it is a text of
    /// its own.
    private func authorTop(_ elements: [(String, CGRect, Bool)], _ label: String) -> CGFloat? {
        guard label.hasPrefix("Item #") else { return nil }
        let pattern = "^[A-Z][A-Za-z'. -]* \(label.dropFirst("Item #".count))$"
        let lines = elements.filter { $0.2 && $0.0.range(of: pattern, options: .regularExpression) != nil }
        return lines.count == 1 ? lines[0].1.minY : nil
    }

    private func messageTop(_ texts: [(String, CGRect)], time: String, sender: String) -> CGFloat? {
        let at = texts.filter { $0.0 == time }
        guard at.count == 1 else { return nil }
        let stamp = at[0].1
        return texts
            .filter { $0.0 == sender && abs($0.1.minX - stamp.minX) <= 3 && $0.1.maxY <= stamp.minY + 1 }
            .map { $0.1.minY }
            .max()
    }
}
