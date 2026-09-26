import XCTest

final class PersonalTrainerAppUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testStrengthLoggingAndHistory() throws {
        let app = launchApp()
        XCTAssertTrue(app.buttons["Group-Chest"].waitForExistence(timeout: 10))
        capture("Train")
        XCTAssertFalse(app.staticTexts["Cardio"].exists)
        app.buttons["Group-Chest"].tap()
        XCTAssertTrue(app.buttons["ExerciseRow_Bench Press"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Warm Up"].exists)
        XCTAssertFalse(app.staticTexts["Cool Down"].exists)
        app.buttons["ExerciseRow_Bench Press"].tap()
        let log = app.buttons["LogSetButton"]
        XCTAssertTrue(log.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["restTimerStartPause"].isHittable)
        log.tap()
        XCTAssertTrue(app.buttons["UndoLastSetButton"].waitForExistence(timeout: 5))
        capture("Exercise")
        app.buttons["UndoLastSetButton"].tap()
        XCTAssertFalse(app.buttons["UndoLastSetButton"].exists)
        log.tap()
        app.buttons["EditSetButton"].firstMatch.tap()
        let reps = app.textFields["EditSetRepsField"]
        XCTAssertTrue(reps.waitForExistence(timeout: 5))
        reps.doubleTap()
        reps.typeText("12")
        XCTAssertEqual(reps.value as? String, "12")
        app.buttons["SaveSetChangesButton"].tap()
        XCTAssertTrue(app.staticTexts["12 reps × 135 lbs"].waitForExistence(timeout: 5))
        app.swipeUp()
        assertAboveTimer(app.buttons["ExerciseInstructionsLink"], in: app)
        app.buttons["restTimerExpand"].tap()
        app.swipeUp()
        assertAboveTimer(app.buttons["ExerciseInstructionsLink"], in: app)
        app.buttons["restTimerExpand"].tap()
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["StrengthHistorySummary"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Bench Press"].waitForExistence(timeout: 5))
        app.swipeUp()
        assertAboveTimer(app.buttons["HistorySetRow"].firstMatch, in: app)
        app.buttons["restTimerExpand"].tap()
        app.swipeUp()
        assertAboveTimer(app.buttons["HistorySetRow"].firstMatch, in: app)
        app.buttons["restTimerExpand"].tap()
        capture("History")
        XCTAssertFalse(app.staticTexts["Cardio"].exists)

        // Deleting in Train must also dismiss an open copy in History.
        let historyExercise = app.staticTexts["Bench Press"]
        for _ in 0..<3 where !historyExercise.isHittable { app.swipeUp() }
        historyExercise.tap()
        XCTAssertTrue(log.waitForExistence(timeout: 5))
        app.tabBars.buttons["Train"].tap()
        app.navigationBars.buttons["Chest"].tap()
        app.buttons["Manage Bench Press"].tap()
        app.buttons["Delete"].tap()
        app.alerts["Delete Exercise?"].buttons["Delete"].tap()
        XCTAssertFalse(app.buttons["ExerciseRow_Bench Press"].exists)
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["StrengthHistorySummary"].waitForExistence(timeout: 5))
        XCTAssertFalse(log.exists)
    }

    @MainActor
    func testGroupCreationAndSharedTimerSettings() throws {
        let app = launchApp()
        XCTAssertTrue(app.buttons["AddGroupButton"].waitForExistence(timeout: 10))
        app.buttons["AddGroupButton"].tap()
        let name = app.textFields["GroupNameField"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Core")
        app.buttons["SaveGroupButton"].tap()
        app.swipeUp()
        XCTAssertTrue(app.buttons["Group-Core"].waitForExistence(timeout: 5))
        app.buttons["AppSettingsButton"].tap()
        let stepper = app.steppers["DefaultRestStepper"]
        XCTAssertTrue(stepper.waitForExistence(timeout: 5))
        stepper.buttons["DefaultRestStepper-Increment"].tap()
        app.buttons["SaveAppSettingsButton"].tap()
        XCTAssertTrue(app.otherElements["Rest timer"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.otherElements["Rest timer"].value as? String, "01:45")
        app.buttons["restTimerStartPause"].tap()
        XCTAssertTrue(app.buttons["restTimerStartPause"].label.contains("Pause"))
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.buttons["restTimerStartPause"].label.contains("Pause"))
        app.buttons["restTimerStartPause"].tap()
        XCTAssertTrue(app.buttons["restTimerStartPause"].label.contains("Start"))
        let controls = app.otherElements["RestTimerControls"]
        XCTAssertFalse(controls.exists)
        app.buttons["restTimerToggleArea"].tap()
        XCTAssertTrue(controls.waitForExistence(timeout: 5))
        app.buttons["Add 15 seconds"].tap()
        XCTAssertTrue(controls.exists)
        app.buttons["restTimerStartPause"].tap()
        XCTAssertTrue(controls.exists)
        app.buttons["restTimerStartPause"].tap()
        app.buttons["restTimerToggleArea"].tap()
        XCTAssertFalse(controls.exists)
        app.buttons["restTimerExpand"].tap()
        XCTAssertTrue(controls.waitForExistence(timeout: 5))
        app.buttons["restTimerExpand"].tap()
        XCTAssertFalse(controls.exists)
    }

    @MainActor
    private func assertAboveTimer(_ element: XCUIElement, in app: XCUIApplication) {
        let timer = app.otherElements["RestTimerBar"]
        XCTAssertTrue(timer.waitForExistence(timeout: 5))
        XCTAssertTrue(element.isHittable)
        XCTAssertLessThanOrEqual(element.frame.maxY, timer.frame.minY + 1,
                                 "Scrolled content must be fully above the timer")
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        return app
    }

    @MainActor
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
