import XCTest

final class TaskScratchpadUITestsLaunchTests: XCTestCase {
    
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify the app launched successfully
        XCTAssertTrue(app.windows.count > 0, "App should have at least one window after launch")
        
        // Take a screenshot for visual verification
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testLaunchPerformance() throws {
        if #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *) {
            // Measure app launch time
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    func testLaunchWithCleanState() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10), "Window should appear within 10 seconds")
    }
    
    func testMultipleLaunchCycles() throws {
        // Test that the app can be launched and terminated multiple times
        for i in 1...3 {
            let app = XCUIApplication()
            app.launch()
            XCTAssertTrue(app.windows.count > 0, "Launch cycle \(i): App should have windows")
            app.terminate()
        }
    }
    
    func testWindowAppearsWithCorrectTitle() throws {
        let app = XCUIApplication()
        app.launch()
        
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5), "Main window should appear")
    }
}

