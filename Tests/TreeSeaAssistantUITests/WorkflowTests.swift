import XCTest
@MainActor final class WorkflowTests:XCTestCase {
    private func launch() -> XCUIApplication {let app=XCUIApplication();app.launchArguments=["--ui-testing"];app.launch();return app}
    private func openMap(_ app:XCUIApplication){let tab=app.tabBars.buttons["地图"];if tab.exists{tab.tap()}else{app.buttons["地图"].firstMatch.tap()}}
    func testMapEditorSelectionSurvivesRotation(){let app=launch();openMap(app);let node=app.buttons["node-1"];XCTAssertTrue(node.waitForExistence(timeout:8));node.tap();XCTAssertTrue(app.buttons["保存"].waitForExistence(timeout:3));XCUIDevice.shared.orientation = .landscapeLeft;XCTAssertTrue(app.buttons["保存"].exists);app.buttons["取消"].tap();XCUIDevice.shared.orientation = .portrait}
    func testPlanAndInventoryWorkflow(){let app=launch();openMap(app);app.buttons["规划条件与推荐路线"].tap();XCTAssertTrue(app.staticTexts["推荐路线"].waitForExistence(timeout:8));let ap=app.textFields["当前行动力"];ap.tap();ap.press(forDuration:1);ap.typeText("1");app.buttons["确认 AP 并重新规划"].tap();XCTAssertTrue(app.buttons["重新计算"].waitForExistence(timeout:8))}
    func testAccessibilitySizeKeepsImportAndCancelReachable(){let app=XCUIApplication();app.launchArguments=["--ui-testing","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"];app.launch();let button=app.buttons["导入地图截图"];if !button.isHittable {app.swipeUp()};XCTAssertTrue(button.waitForExistence(timeout:5));button.tap();XCTAssertTrue(app.buttons["取消"].waitForExistence(timeout:5));app.buttons["取消"].tap()}
}
