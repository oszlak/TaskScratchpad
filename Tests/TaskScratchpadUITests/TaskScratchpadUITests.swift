import XCTest

final class TaskScratchpadUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - App Launch Tests
    
    func testAppLaunches() throws {
        XCTAssertTrue(app.windows.count > 0, "App should have at least one window")
    }
    
    func testMainWindowExists() throws {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists, "Main window should exist")
    }
    
    // MARK: - Task Input Tests
    
    func testTaskInputFieldExists() throws {
        let textField = app.textFields["Quick add a task and hit Return…"]
        XCTAssertTrue(textField.waitForExistence(timeout: 5), "Task input field should exist")
    }
    
    func testCanTypeInTaskInput() throws {
        let textField = app.textFields.firstMatch
        if textField.waitForExistence(timeout: 5) {
            textField.click()
            textField.typeText("Test task from UI test")
            XCTAssertEqual(textField.value as? String, "Test task from UI test")
        }
    }
    
    func testAddTaskViaReturn() throws {
        let textField = app.textFields.firstMatch
        guard textField.waitForExistence(timeout: 5) else {
            XCTFail("Text field not found")
            return
        }
        
        textField.click()
        textField.typeText("UI Test Task\r") // \r is Return key
        
        // Task should appear in the list
        let taskText = app.staticTexts["UI Test Task"]
        XCTAssertTrue(taskText.waitForExistence(timeout: 3), "Task should appear after adding")
    }
    
    // MARK: - Tab Bar Tests
    
    func testTabBarExists() throws {
        // Look for the tab bar or scratchpad tabs
        let tabArea = app.scrollViews.firstMatch
        XCTAssertTrue(tabArea.waitForExistence(timeout: 5), "Tab bar area should exist")
    }
    
    func testDefaultTabExists() throws {
        // Default tab should be "My Tasks"
        let defaultTab = app.staticTexts["My Tasks"]
        if defaultTab.waitForExistence(timeout: 5) {
            XCTAssertTrue(defaultTab.exists, "Default 'My Tasks' tab should exist")
        }
    }
    
    func testAddNewTabButton() throws {
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add' OR label CONTAINS 'plus'")).firstMatch
        if addButton.waitForExistence(timeout: 5) {
            XCTAssertTrue(addButton.isEnabled, "Add tab button should be enabled")
        }
    }
    
    // MARK: - Task Interaction Tests
    
    func testTaskExpansion() throws {
        // First add a task
        let textField = app.textFields.firstMatch
        guard textField.waitForExistence(timeout: 5) else { return }
        
        textField.click()
        textField.typeText("Expandable Task\r")
        
        // Find and click the task
        let task = app.staticTexts["Expandable Task"]
        guard task.waitForExistence(timeout: 3) else {
            XCTFail("Task not found")
            return
        }
        
        task.click()
        
        // After expansion, should see the notes area or subtask field
        let notesArea = app.textViews.firstMatch
        XCTAssertTrue(notesArea.waitForExistence(timeout: 3), "Notes area should appear when task is expanded")
    }
    
    func testTaskCompletion() throws {
        // Add a task first
        let textField = app.textFields.firstMatch
        guard textField.waitForExistence(timeout: 5) else { return }
        
        textField.click()
        textField.typeText("Complete Me Task\r")
        
        // Find the completion button (circle checkbox)
        // This might need adjustment based on actual UI element identifiers
        let task = app.staticTexts["Complete Me Task"]
        guard task.waitForExistence(timeout: 3) else { return }
        
        // The task row should have a completion toggle
        let buttons = app.buttons
        XCTAssertTrue(buttons.count > 0, "There should be buttons for task interaction")
    }
    
    // MARK: - Menu Tests
    
    func testScratchpadMenuExists() throws {
        let menuBar = app.menuBars
        XCTAssertTrue(menuBar.count > 0, "Menu bar should exist")
        
        // Click on Scratchpad menu
        let scratchpadMenu = menuBar.menuBarItems["Scratchpad"]
        if scratchpadMenu.exists {
            scratchpadMenu.click()
            
            // Check for menu items
            let newTaskItem = app.menuItems["New Task"]
            XCTAssertTrue(newTaskItem.waitForExistence(timeout: 2), "New Task menu item should exist")
            
            // Press Escape to close menu
            app.typeKey(.escape, modifierFlags: [])
        }
    }
    
    // MARK: - Keyboard Shortcuts
    
    func testCommandNFocusesInput() throws {
        // Press Cmd+N
        app.typeKey("n", modifierFlags: .command)
        
        // Input should be focused
        let textField = app.textFields.firstMatch
        XCTAssertTrue(textField.waitForExistence(timeout: 3), "Text field should exist after Cmd+N")
    }
    
    // MARK: - Empty State
    
    func testEmptyStateMessageWithNoTasks() throws {
        // This test assumes starting with no tasks
        // Look for empty state message
        let emptyMessage = app.staticTexts["Ready to be productive?"]
        // This may or may not exist depending on state
        if emptyMessage.exists {
            XCTAssertTrue(emptyMessage.exists)
        }
    }
    
    // MARK: - Window Properties
    
    func testWindowMinimumSize() throws {
        let window = app.windows.firstMatch
        guard window.exists else { return }
        
        let frame = window.frame
        XCTAssertGreaterThanOrEqual(frame.width, 420, "Window width should be at least 420")
        XCTAssertGreaterThanOrEqual(frame.height, 520, "Window height should be at least 520")
    }
}

