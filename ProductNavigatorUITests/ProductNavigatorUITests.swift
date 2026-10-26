import XCTest

final class ProductNavigatorUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testEachProductOpensItsDetailAndReturnsToList() {
        let app = XCUIApplication()
        app.launch()

        let products = [
            (name: "Notebook", description: "A hardcover notebook for everyday ideas."),
            (name: "Desk Lamp", description: "An adjustable lamp for a comfortable workspace."),
            (name: "Travel Mug", description: "An insulated mug for drinks on the go.")
        ]

        XCTAssertTrue(app.navigationBars["Products"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.tables.cells.count, products.count)

        for product in products {
            let row = app.tables.cells.containing(.staticText, identifier: product.name).firstMatch
            XCTAssertTrue(row.waitForExistence(timeout: 5))
            row.tap()

            let detailBar = app.navigationBars[product.name]
            XCTAssertTrue(detailBar.waitForExistence(timeout: 5))
            XCTAssertTrue(app.scrollViews.staticTexts[product.name].exists)
            XCTAssertTrue(app.scrollViews.staticTexts[product.description].exists)

            detailBar.buttons["Products"].tap()
            XCTAssertTrue(app.navigationBars["Products"].waitForExistence(timeout: 5))
            XCTAssertTrue(row.waitForExistence(timeout: 5))
        }
    }
}
