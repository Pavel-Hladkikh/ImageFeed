@testable import ImageFeed
import Foundation

final class ProfilePresenterSpy: ProfilePresenting {
    private(set) var viewDidLoadCalled = false
    private(set) var didTapLogoutCalled = false

    func viewDidLoad() { viewDidLoadCalled = true }
    func didTapLogout() { didTapLogoutCalled = true }
}
