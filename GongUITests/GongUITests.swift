import XCTest

/// Ceremonial verification: launch the gallery, strike the gong, and keep
/// photographic evidence. Screenshots are attached to the result bundle and
/// surfaced as CI artifacts.
final class GongUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testStrikeTheGongAndCaptureEvidence() throws {
        let app = XCUIApplication()
        app.launch()

        // Let the unveiling finish and the synthesized instrument render.
        Thread.sleep(forTimeInterval: 3.0)
        capture(app, name: "01-the-gallery")

        let gong = app.buttons["The gong"]
        XCTAssertTrue(gong.waitForExistence(timeout: 10), "The gong must hang in the gallery.")

        // A quick tap: soft strike.
        gong.tap()
        Thread.sleep(forTimeInterval: 0.5)
        capture(app, name: "02-soft-strike")

        Thread.sleep(forTimeInterval: 1.2)
        capture(app, name: "03-resonance")

        // A full wind-up: the mallet draws back, then lands hard.
        gong.press(forDuration: 1.3)
        Thread.sleep(forTimeInterval: 0.4)
        capture(app, name: "04-hard-strike")

        Thread.sleep(forTimeInterval: 1.0)
        capture(app, name: "05-ring-down")
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
