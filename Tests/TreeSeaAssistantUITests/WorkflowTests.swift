import XCTest
@MainActor final class WorkflowTests:XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure=false
        addUIInterruptionMonitor(withDescription:"首次启动无线数据提示"){alert in
            guard alert.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","使用无线数据")).firstMatch.exists else {return false}
            alert.buttons["不允许"].tap()
            return true
        }
    }
    override func tearDownWithError() throws {
        let attachment=XCTAttachment(screenshot:XCUIApplication().screenshot())
        attachment.name=name
        attachment.lifetime = .keepAlways
        add(attachment)
        XCUIDevice.shared.orientation = .portrait
        try super.tearDownWithError()
    }
    private func launch() -> XCUIApplication {let app=XCUIApplication();app.launchArguments=["--ui-testing"];app.launch();return app}
    private func openMap(_ app:XCUIApplication){let tab=app.tabBars.buttons["地图"];if tab.exists{tab.tap()}else{app.buttons["地图"].firstMatch.tap()}}
    func testMapEditorSelectionSurvivesRotation(){let app=launch();openMap(app);let node=app.buttons["node-1"];XCTAssertTrue(node.waitForExistence(timeout:8));node.tap();if app.buttons["编辑节点"].exists {app.buttons["编辑节点"].tap()};XCTAssertTrue(app.buttons["保存"].waitForExistence(timeout:3));XCUIDevice.shared.orientation = .landscapeLeft;XCTAssertTrue(app.buttons["保存"].exists);app.buttons["取消"].tap();XCUIDevice.shared.orientation = .portrait}
    func testPlanAndInventoryWorkflow(){
        let app=launch()
        openMap(app)
        app.buttons["规划条件与推荐路线"].tap()
        XCTAssertTrue(app.staticTexts["推荐路线"].waitForExistence(timeout:8))
        let ap=app.textFields["当前行动力"]
        ap.tap()
        let oldValue=ap.value as? String ?? ""
        ap.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:oldValue.count)+"1")
        XCTAssertEqual(ap.value as? String,"1")
        app.buttons["ap-keyboard-done"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout:3))
        app.buttons["确认 AP 并重新规划"].tap()
        XCTAssertTrue(app.staticTexts["已确认 AP：1"].waitForExistence(timeout:5))
        XCTAssertTrue(app.buttons["重新计算"].waitForExistence(timeout:8))
        app.buttons["加工品与次数"].tap()
        XCTAssertTrue(app.buttons["手动添加实例"].waitForExistence(timeout:5))
        app.buttons["手动添加实例"].tap()
        let charges=app.textFields["实际剩余次数（必填）"]
        XCTAssertTrue(charges.waitForExistence(timeout:5))
        charges.tap()
        charges.typeText("2")
        app.buttons["charges-keyboard-done"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout:3))
        let reviewed=app.switches["已核对名称、射程、消耗和剩余次数"]
        for _ in 0..<3 where !reviewed.isHittable {app.collectionViews.firstMatch.swipeUp()}
        XCTAssertTrue(reviewed.isHittable)
        reviewed.coordinate(withNormalizedOffset:CGVector(dx:0.95,dy:0.5)).tap()
        XCTAssertEqual(reviewed.value as? String,"1")
        XCTAssertTrue(app.buttons["保存"].isEnabled)
        app.buttons["保存"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","剩余 2 次")).firstMatch.waitForExistence(timeout:5))
    }
    func testReferenceMapImportAndNewTheme() {
        let app=XCUIApplication();app.launchArguments=["--ui-testing","--ui-import-map"];app.launch()
        let importButton=app.buttons["导入地图截图"]
        XCTAssertTrue(importButton.waitForExistence(timeout:8))
        XCTAssertGreaterThanOrEqual(importButton.frame.minX,app.frame.minX)
        XCTAssertLessThanOrEqual(importButton.frame.maxX,app.frame.maxX)
        let home=XCTAttachment(screenshot:app.screenshot());home.name="新版会话封面";home.lifetime = .keepAlways;add(home)
        importButton.tap()
        let recognize=app.buttons["生成识别提案"]
        XCTAssertTrue(recognize.waitForExistence(timeout:8))
        if !recognize.isHittable {app.swipeUp()}
        recognize.tap()
        let summary=app.staticTexts.matching(NSPredicate(format:"label BEGINSWITH %@","识别到 12 个节点")).firstMatch
        for _ in 0..<5 where !summary.isHittable {if summary.exists {app.swipeUp()} else { _=summary.waitForExistence(timeout:4) }}
        XCTAssertTrue(summary.exists)
        XCTAssertTrue(app.staticTexts["地图确认提案"].exists)
        let proposal=XCTAttachment(screenshot:app.screenshot());proposal.name="真实地图识别提案";proposal.lifetime = .keepAlways;add(proposal)
        app.buttons["取消"].firstMatch.tap()
        openMap(app)
        let mystery=app.buttons["node-7"]
        XCTAssertTrue(mystery.waitForExistence(timeout:5))
        let map=XCTAttachment(screenshot:app.screenshot());map.name="原版风格地图与透明起点";map.lifetime = .keepAlways;add(map)
        app.buttons["放大"].tap()
        mystery.tap()
        if app.buttons["取消"].exists {app.buttons["取消"].tap()}
        let candidates=app.staticTexts["可能类型"]
        for _ in 0..<6 where !candidates.isHittable {app.swipeUp()}
        XCTAssertTrue(candidates.exists)
        let statistics=XCTAttachment(screenshot:app.screenshot());statistics.name="候选与概率接口占位";statistics.lifetime = .keepAlways;add(statistics)
    }
    func testAccessibilitySizeKeepsImportAndCancelReachable(){let app=XCUIApplication();app.launchArguments=["--ui-testing","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"];app.launch();let button=app.buttons["导入地图截图"];if !button.isHittable {app.swipeUp()};XCTAssertTrue(button.waitForExistence(timeout:5));button.tap();XCTAssertTrue(app.buttons["取消"].waitForExistence(timeout:5));app.buttons["取消"].tap()}
}
