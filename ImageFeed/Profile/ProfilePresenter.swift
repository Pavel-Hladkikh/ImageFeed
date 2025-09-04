import Foundation
import UIKit

protocol ProfileView: AnyObject {
    func setLoading(_ isLoading: Bool)
    func showName(_ text: String)
    func showLogin(_ text: String)
    func showBio(_ text: String?, hideAfterLoading: Bool)
    func showAvatar(urlString: String?)
    func routeToSplashAfterLogout()
}

protocol ProfilePresenting: AnyObject {
    func viewDidLoad()
    func didTapLogout()
}

protocol ProfileServiceProtocol: AnyObject {
    var profile: Profile? { get }
    static var didChangeNotification: Notification.Name { get }
}
protocol ProfileImageServiceProtocol: AnyObject {
    var avatarURL: String? { get }
    static var didChangeNotification: Notification.Name { get }
}
protocol ProfileLogoutServiceProtocol: AnyObject {
    func logout()
}

extension ProfileService: ProfileServiceProtocol {}
extension ProfileImageService: ProfileImageServiceProtocol {}
extension ProfileLogoutService: ProfileLogoutServiceProtocol {}

final class ProfilePresenter: ProfilePresenting {
    
    private weak var view: ProfileView?
    private let profileService: ProfileServiceProtocol
    private let imageService: ProfileImageServiceProtocol
    private let logoutService: ProfileLogoutServiceProtocol
    
    private var hasProfile = false
    private var hasAvatar  = false
    
    private var profileObserver: NSObjectProtocol?
    private var avatarObserver: NSObjectProtocol?
    
    init(view: ProfileView,
         profileService: ProfileServiceProtocol = ProfileService.shared,
         imageService: ProfileImageServiceProtocol = ProfileImageService.shared,
         logoutService: ProfileLogoutServiceProtocol = ProfileLogoutService.shared) {
        self.view = view
        self.profileService = profileService
        self.imageService = imageService
        self.logoutService = logoutService
    }
    
    deinit {
        if let o = profileObserver { NotificationCenter.default.removeObserver(o) }
        if let o = avatarObserver  { NotificationCenter.default.removeObserver(o) }
    }
    
    func viewDidLoad() {
        view?.setLoading(true)
        
        if let p = profileService.profile {
            applyProfile(p)
        } else {
            hasProfile = false
        }
        
        let url = imageService.avatarURL
        view?.showAvatar(urlString: url)
        hasAvatar = (url != nil)
        
        tryFinish()
        
        profileObserver = NotificationCenter.default.addObserver(
            forName: type(of: profileService).didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, let p = self.profileService.profile else { return }
            self.applyProfile(p)
            self.tryFinish()
        }
        
        avatarObserver = NotificationCenter.default.addObserver(
            forName: type(of: imageService).didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let url = self.imageService.avatarURL
            self.view?.showAvatar(urlString: url)
            self.hasAvatar = (url != nil)
            self.tryFinish()
        }
    }
    
    func didTapLogout() {
        logoutService.logout()
        view?.routeToSplashAfterLogout()
    }
    
    private func applyProfile(_ profile: Profile) {
        view?.showName(profile.name)
        view?.showLogin(profile.loginName)
        
        let bioText = profile.bio?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hide = (bioText?.isEmpty ?? true)
        view?.showBio(hide ? nil : bioText, hideAfterLoading: hide)
        
        hasProfile = true
    }
    
    private func tryFinish() {
        if hasProfile && hasAvatar {
            view?.setLoading(false)
        }
    }
}


