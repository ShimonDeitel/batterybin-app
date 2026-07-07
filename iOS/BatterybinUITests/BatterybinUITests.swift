import XCTest

final class BatterybinUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testAddEntryFlow() {
        app.buttons["addButton"].tap()
        let titleField = app.textFields["field_title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        titleField.tap()
        titleField.typeText("UI Test Entry")
        app.buttons["saveButton"].tap()
        XCTAssertTrue(app.staticTexts["UI Test Entry"].waitForExistence(timeout: 2))
    }

    func testKeyboardDismissOnTapOutside() {
        app.buttons["addButton"].tap()
        let titleField = app.textFields["field_title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        titleField.tap()
        titleField.typeText("Dismiss Me")
        XCTAssertTrue(app.keyboards.element.exists)
        app.navigationBars.firstMatch.tap()
        XCTAssertFalse(app.keyboards.element.exists)
    }

    func testFreeLimitTriggersPaywall() {
        for i in 0..<(9) {
            app.buttons["addButton"].tap()
            let titleField = app.textFields["field_title"]
            if titleField.waitForExistence(timeout: 2) {
                titleField.tap()
                titleField.typeText("Entry \(i)")
                app.buttons["saveButton"].tap()
            } else {
                break
            }
        }
        app.buttons["addButton"].tap()
        XCTAssertTrue(app.buttons["purchaseButton"].waitForExistence(timeout: 2))
    }

    func testSettingsOpensAndCloses() {
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.buttons["doneButton"].waitForExistence(timeout: 2))
        app.buttons["doneButton"].tap()
    }

    func testCancelAddEntryDiscardsDraft() {
        app.buttons["addButton"].tap()
        let titleField = app.textFields["field_title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        titleField.tap()
        titleField.typeText("Should Not Save")
        app.buttons["cancelButton"].tap()
        XCTAssertFalse(app.staticTexts["Should Not Save"].exists)
    }
}
