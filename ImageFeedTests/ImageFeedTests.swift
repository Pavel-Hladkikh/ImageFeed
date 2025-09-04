import XCTest
import UIKit

final class ImageFeedUITests: XCTestCase {
    private var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testAuth() throws {
        
        let authButton = app.buttons["Authenticate"]
        XCTAssertTrue(authButton.waitForExistence(timeout: 10))
        authButton.tap()
        
        let webView = app.webViews["UnsplashWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 15))
        
        let emailField = webView.textFields.element(boundBy: 0)
        XCTAssertTrue(emailField.waitForExistence(timeout: 10))
        emailField.tap()
        emailField.typeText("login")
        app.toolbars.buttons["Done"].tap()
        
        sleep(1)
        let passwordField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordField.waitForExistence(timeout: 10))
        passwordField.tap()
        sleep(1)
        passwordField.typeText("password")
        app.toolbars.buttons["Done"].tap()
        
        sleep(1)
        let loginButton = webView.buttons["Login"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 10))
        loginButton.tap()
        
        XCTAssertTrue(webView.waitForNonExistence(timeout: 15))
        
        let feedTable = app.tables["ImagesListTable"]
        XCTAssertTrue(feedTable.waitForExistence(timeout: 20), "Таблица ленты не появилась")
        
        let firstCell = feedTable.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 20))
    }
    
    func testFeed() throws {
        let tables = app.tables
        let firstCell = tables.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 12), "Лента не загрузилась")
        
        firstCell.swipeUp()
        sleep(1)
        
        let secondCell = tables.children(matching: .cell).element(boundBy: 1)
        XCTAssertTrue(secondCell.waitForExistence(timeout: 8), "Вторая ячейка не появилась")
        if secondCell.buttons["like button off"].exists {
            secondCell.buttons["like button off"].tap()
        }
        if secondCell.buttons["like button on"].exists {
            secondCell.buttons["like button on"].tap()
        }
        
        secondCell.tap()
        sleep(1)
        
        let image = app.scrollViews.images.element(boundBy: 0)
        XCTAssertTrue(image.waitForExistence(timeout: 8), "Полноэкранное изображение не появилось")
        image.pinch(withScale: 3, velocity: 1)
        image.pinch(withScale: 0.5, velocity: -1)
        
        app.buttons["nav back button white"].tap()
        XCTAssertTrue(firstCell.waitForExistence(timeout: 6), "Не вернулись к ленте")
    }
    
    func testProfile() throws {
        let firstCell = app.tables.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 12), "Лента не загрузилась")
        
        app.tabBars.buttons.element(boundBy: 1).tap()
        
        XCTAssertTrue(app.staticTexts["profile_name_label"].exists, "Имя не отображается")
        XCTAssertTrue(app.staticTexts["profile_login_label"].exists, "Логин не отображается")
        
        app.buttons["logout button"].tap()
        
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 6), "Алерт выхода не показан")
        alert.buttons["Да"].tap()
        
        XCTAssertTrue(app.buttons["Authenticate"].waitForExistence(timeout: 10), "Экран авторизации не появился")
    }
}








