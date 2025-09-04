import UIKit
import Kingfisher

final class ProfileViewController: UIViewController, ProfileView {
    
    var presenter: ProfilePresenting!
    
    private enum SkeletonLayout {
        static let height: CGFloat = 18
        static let radius: CGFloat = 9
        static let nameWidth:  CGFloat = 223
        static let loginWidth: CGFloat = 89
        static let bioWidth:   CGFloat = 67
    }
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 35
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let logoutButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(named: "logout_button"), for: .normal)
        b.tintColor = UIColor(red: 0xF5/255, green: 0x6B/255, blue: 0x6C/255, alpha: 1)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.accessibilityIdentifier = "logout button"
        return b
    }()
    
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 23, weight: .semibold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        l.accessibilityIdentifier = "profile_name_label"
        return l
    }()
    
    private let loginNameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = UIColor(red: 0xAE/255, green: 0xAF/255, blue: 0xB4/255, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.accessibilityIdentifier = "profile_login_label"
        return l
    }()
    
    private let descriptionLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = .white
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private var avatarGradient: LoadingGradientView?
    private var nameGradient: LoadingGradientView?
    private var loginGradient: LoadingGradientView?
    private var bioGradient: LoadingGradientView?
    private var nameHeightWhenSkeleton: NSLayoutConstraint?
    
    private var isProfileLoaded = false
    private var isAvatarLoaded  = false
    private var didFinishLoading = false
    private var shouldHideBioAfterLoading = false
    private var isLoading: Bool { !didFinishLoading && !(isProfileLoaded && isAvatarLoaded) }
    
    private var savedNameColor: UIColor?
    private var savedLoginColor: UIColor?
    private var savedBioColor: UIColor?
    
    private let minSkeletonDuration: CFTimeInterval = 0.6
    private var skeletonStartTime: CFTimeInterval = 0
    
    private var avatarRetryCount = 0
    private let maxAvatarRetryCount = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 1)
        setupSubviews()
        setupConstraints()
        logoutButton.addTarget(self, action: #selector(didTapLogoutButton), for: .touchUpInside)
        
        showSkeletonNow()
        
        presenter.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isLoading {
            startAvatarSkeletonIfNeeded()
            startFixedTextSkeletonsIfNeeded()
        }
    }
    
    private func setupSubviews() {
        view.addSubview(avatarImageView)
        view.addSubview(logoutButton)
        view.addSubview(nameLabel)
        view.addSubview(loginNameLabel)
        view.addSubview(descriptionLabel)
    }
    
    private func setupConstraints() {
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: safe.topAnchor, constant: 32),
            avatarImageView.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 70),
            avatarImageView.heightAnchor.constraint(equalToConstant: 70),
            
            logoutButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -16),
            logoutButton.widthAnchor.constraint(equalToConstant: 44),
            logoutButton.heightAnchor.constraint(equalToConstant: 44),
            
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -16),
            
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            loginNameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            loginNameLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            loginNameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: SkeletonLayout.height),
            descriptionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: SkeletonLayout.height)
        ])
    }
    
    private func showSkeletonNow() {
        didFinishLoading = false
        isProfileLoaded = false
        isAvatarLoaded  = false
        skeletonStartTime = CACurrentMediaTime()
        
        view.layoutIfNeeded()
        
        logoutButton.isHidden = true
        
        if avatarGradient == nil {
            avatarGradient = avatarImageView.addLoadingGradient(cornerRadius: 35)
        }
        
        if savedNameColor == nil { savedNameColor = nameLabel.textColor }
        if savedLoginColor == nil { savedLoginColor = loginNameLabel.textColor }
        if savedBioColor == nil { savedBioColor = descriptionLabel.textColor }
        
        nameLabel.textColor = .clear
        loginNameLabel.textColor = .clear
        descriptionLabel.textColor = .clear
        descriptionLabel.isHidden = false
        
        if nameHeightWhenSkeleton == nil {
            let c = nameLabel.heightAnchor.constraint(equalToConstant: SkeletonLayout.height)
            c.isActive = true
            nameHeightWhenSkeleton = c
            view.layoutIfNeeded()
        }
        
        if nameGradient == nil {
            nameGradient  = nameLabel.addLoadingGradientFixedWidth(
                width: SkeletonLayout.nameWidth, height: SkeletonLayout.height,
                cornerRadius: SkeletonLayout.radius, align: .center
            )
        }
        if loginGradient == nil {
            loginGradient = loginNameLabel.addLoadingGradientFixedWidth(
                width: SkeletonLayout.loginWidth, height: SkeletonLayout.height,
                cornerRadius: SkeletonLayout.radius, align: .center
            )
        }
        if bioGradient == nil {
            bioGradient   = descriptionLabel.addLoadingGradientFixedWidth(
                width: SkeletonLayout.bioWidth, height: SkeletonLayout.height,
                cornerRadius: SkeletonLayout.radius, align: .center
            )
        }
    }
    
    private func startAvatarSkeletonIfNeeded() {
        guard isLoading, avatarGradient == nil else { return }
        avatarGradient = avatarImageView.addLoadingGradient(cornerRadius: 35)
        logoutButton.isHidden = true
    }
    
    private func startFixedTextSkeletonsIfNeeded() {
        guard isLoading else { return }
        guard nameGradient == nil && loginGradient == nil && bioGradient == nil else { return }
        guard view.bounds.width > 0 else { return }
        
        if savedNameColor == nil { savedNameColor = nameLabel.textColor }
        if savedLoginColor == nil { savedLoginColor = loginNameLabel.textColor }
        if savedBioColor == nil { savedBioColor = descriptionLabel.textColor }
        
        nameLabel.textColor = .clear
        loginNameLabel.textColor = .clear
        descriptionLabel.textColor = .clear
        descriptionLabel.isHidden = false
        
        if nameHeightWhenSkeleton == nil {
            let c = nameLabel.heightAnchor.constraint(equalToConstant: SkeletonLayout.height)
            c.isActive = true
            nameHeightWhenSkeleton = c
            view.layoutIfNeeded()
        }
        
        nameGradient  = nameLabel.addLoadingGradientFixedWidth(
            width: SkeletonLayout.nameWidth, height: SkeletonLayout.height,
            cornerRadius: SkeletonLayout.radius, align: .center
        )
        loginGradient = loginNameLabel.addLoadingGradientFixedWidth(
            width: SkeletonLayout.loginWidth, height: SkeletonLayout.height,
            cornerRadius: SkeletonLayout.radius, align: .center
        )
        bioGradient   = descriptionLabel.addLoadingGradientFixedWidth(
            width: SkeletonLayout.bioWidth, height: SkeletonLayout.height,
            cornerRadius: SkeletonLayout.radius, align: .center
        )
    }
    
    private func removeAllLoadingGradients(from root: UIView) {
        for sub in root.subviews {
            if let g = sub as? LoadingGradientView { g.stop() }
            removeAllLoadingGradients(from: sub)
        }
    }
    
    private func stopAllSkeletonsRespectingMinDuration() {
        let elapsed = CACurrentMediaTime() - skeletonStartTime
        let delay = max(minSkeletonDuration - elapsed, 0)
        
        let work = { [weak self] in
            guard let self else { return }
            self.nameGradient?.stop();   self.nameGradient = nil
            self.loginGradient?.stop();  self.loginGradient = nil
            self.bioGradient?.stop();    self.bioGradient = nil
            self.avatarGradient?.stop(); self.avatarGradient = nil
            
            self.nameHeightWhenSkeleton?.isActive = false
            self.nameHeightWhenSkeleton = nil
            
            self.removeAllLoadingGradients(from: self.view)
            
            self.nameLabel.textColor  = self.savedNameColor  ?? .white
            self.loginNameLabel.textColor = self.savedLoginColor
            ?? UIColor(red: 0xAE/255, green: 0xAF/255, blue: 0xB4/255, alpha: 1)
            self.descriptionLabel.textColor = self.savedBioColor ?? .white
            self.descriptionLabel.isHidden = self.shouldHideBioAfterLoading
            
            self.logoutButton.isHidden = false
            
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
        
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        } else {
            work()
        }
    }
    
    private func updateLoadingStateFromFlags() {
        let ready = isProfileLoaded && isAvatarLoaded
        if ready && !didFinishLoading {
            didFinishLoading = true
            stopAllSkeletonsRespectingMinDuration()
        }
    }
    
    @objc private func didTapLogoutButton() {
        presentLogoutAlert()
    }
    
    private func presentLogoutAlert() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        
        let title = NSAttributedString(
            string: "Пока, пока!",
            attributes: [
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
                .foregroundColor: UIColor(named: "YP Black (iOS)") ?? .black
            ])
        let message = NSAttributedString(
            string: "Уверены, что хотите выйти?",
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: UIColor(named: "YP Black (iOS)") ?? .black
            ])
        alert.setValue(title, forKey: "attributedTitle")
        alert.setValue(message, forKey: "attributedMessage")
        alert.view.tintColor = UIColor(named: "YP Blue (iOS)") ?? view.tintColor
        
        let yes = UIAlertAction(title: "Да", style: .default) { [weak self] _ in
            self?.presenter.didTapLogout()
        }
        let no  = UIAlertAction(title: "Нет", style: .default, handler: nil)
        alert.addAction(yes)
        alert.addAction(no)
        alert.preferredAction = no
        
        present(alert, animated: true)
    }
    
    func setLoading(_ isLoading: Bool) {
        if isLoading {
            showSkeletonNow()
        } else {
            didFinishLoading = true
            stopAllSkeletonsRespectingMinDuration()
        }
    }
    
    func showName(_ text: String) {
        nameLabel.text = text
        isProfileLoaded = true
        updateLoadingStateFromFlags()
    }
    
    func showLogin(_ text: String) {
        loginNameLabel.text = text
    }
    
    func showBio(_ text: String?, hideAfterLoading: Bool) {
        shouldHideBioAfterLoading = hideAfterLoading
        descriptionLabel.text = text
    }
    
    func showAvatar(urlString: String?) {
        guard let urlString, let url = URL(string: urlString) else {
            avatarImageView.image = UIImage(named: "Avatar")
            isAvatarLoaded = true
            updateLoadingStateFromFlags()
            return
        }
        
        avatarImageView.kf.setImage(
            with: url,
            placeholder: UIImage(named: "Avatar"),
            options: [.transition(.fade(0.25))]
        ) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.avatarRetryCount = 0
                self.isAvatarLoaded = true
                self.updateLoadingStateFromFlags()
            case .failure:
                self.avatarImageView.image = UIImage(named: "Avatar")
                self.isAvatarLoaded = true
                self.updateLoadingStateFromFlags()
            }
        }
    }
    
    func routeToSplashAfterLogout() {
        guard let window = UIApplication.shared.windows.first else { return }
        window.rootViewController = SplashViewController()
        window.makeKeyAndVisible()
    }
}








