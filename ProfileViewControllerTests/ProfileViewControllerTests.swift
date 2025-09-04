@testable import ImageFeed
import XCTest
import UIKit

final class ProfileViewControllerTests: XCTestCase {
    private var window: UIWindow!
    
    private func makeVC(presenter: ProfilePresenting = ProfilePresenterSpy()) -> ProfileViewController {
        let vc = ProfileViewController()
        vc.presenter = presenter
        vc.loadViewIfNeeded()
        return vc
    }
    
    private func hostInWindow(_ vc: UIViewController) {
        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = vc
        window.makeKeyAndVisible()
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
    }
    
    private func findButton(_ root: UIView, _ id: String) -> UIButton? {
        if let b = root as? UIButton, b.accessibilityIdentifier == id { return b }
        for sub in root.subviews { if let r = findButton(sub, id) { return r } }
        return nil
    }
    
    private func findLabel(_ root: UIView, _ id: String) -> UILabel? {
        if let l = root as? UILabel, l.accessibilityIdentifier == id { return l }
        for sub in root.subviews { if let r = findLabel(sub, id) { return r } }
        return nil
    }
    
    override func tearDown() {
        window?.isHidden = true
        window = nil
        super.tearDown()
    }
    
    func test_viewDidLoad_callsPresenter_andHidesLogoutWhileLoading() {
        let presenter = ProfilePresenterSpy()
        let vc = makeVC(presenter: presenter)
        
        XCTAssertTrue(presenter.viewDidLoadCalled, "viewDidLoad презентера должен вызваться")
        
        let logout = findButton(vc.view, "logout button")
        XCTAssertNotNil(logout, "Кнопка Logout должна существовать")
        XCTAssertTrue(logout!.isHidden, "Пока идёт загрузка — кнопка скрыта")
    }
    
    func test_setLoadingFalse_eventuallyShowsLogoutButton_afterSkeletonDelay() {
        let vc = makeVC()
        let logout = findButton(vc.view, "logout button")!
        XCTAssertTrue(logout.isHidden)
        
        vc.setLoading(false)
        
        let exp = expectation(description: "Logout visible after skeleton")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertFalse(logout.isHidden, "После завершения шимера кнопка должна показаться")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
    }
    
    func test_showNameAndLogin_updateLabels() {
        let vc = makeVC()
        
        vc.showName("Pavel")
        vc.showLogin("@pavel")
        
        let name = findLabel(vc.view, "profile_name_label")
        let login = findLabel(vc.view, "profile_login_label")
        
        XCTAssertEqual(name?.text, "Pavel")
        XCTAssertEqual(login?.text, "@pavel")
    }
    
    func test_logoutAlert_yesCallsPresenter() {
        let presenter = ProfilePresenterSpy()
        let vc = makeVC(presenter: presenter)
        
        hostInWindow(vc)
        
        vc.setLoading(false)
        
        let expShow = expectation(description: "Alert presented")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let logout = self.findButton(vc.view, "logout button")!
            logout.sendActions(for: .touchUpInside)
            
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
            
            XCTAssertTrue(vc.presentedViewController is UIAlertController, "Должен показаться UIAlertController")
            expShow.fulfill()
        }
        wait(for: [expShow], timeout: 2.0)
        
        guard let alert = vc.presentedViewController as? UIAlertController else {
            return XCTFail("UIAlertController не показан")
        }
        let yes = alert.actions.first { $0.title == "Да" }
        XCTAssertNotNil(yes, "Ожидается кнопка 'Да'")
        
        typealias HandlerBlock = @convention(block) (UIAlertAction) -> Void
        var handlerAny: Any?
        handlerAny = yes?.value(forKey: "handler")
        if handlerAny == nil { handlerAny = yes?.value(forKey: "_handler") }
        if let block = handlerAny {
            let imp = unsafeBitCast(block as AnyObject, to: HandlerBlock.self)
            imp(yes!)
        } else {
            XCTFail("Не удалось извлечь handler у UIAlertAction")
        }
        
        XCTAssertTrue(presenter.didTapLogoutCalled, "Нажатие 'Да' должно вызвать didTapLogout у презентера")
    }
    
    func test_showBio_smoke() {
        let vc = makeVC()
        vc.showBio("   ", hideAfterLoading: true)
        vc.setLoading(false)
        XCTAssertTrue(true)
    }
    
    func test_showAvatar_smoke() {
        let vc = makeVC()
        vc.showAvatar(urlString: nil)
        XCTAssertTrue(true)
    }
}


