import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {
    
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
        return b
    }()
    
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 23, weight: .semibold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let loginNameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = UIColor(red: 0xAE/255, green: 0xAF/255, blue: 0xB4/255, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
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
    
    
    private let profileService = ProfileService.shared
    private var profileImageServiceObserver: NSObjectProtocol?
    
    private var avatarGradient: LoadingGradientView?
    private var nameGradient: LoadingGradientView?
    private var loginGradient: LoadingGradientView?
    private var bioGradient: LoadingGradientView?
    
    private var nameHeightWhenSkeleton: NSLayoutConstraint?
    
    private var isProfileLoaded = false { didSet { onStateChange() } }
    private var isAvatarLoaded  = false { didSet { onStateChange() } }
    private var isLoading: Bool { !(isProfileLoaded && isAvatarLoaded) }
    
    private var shouldHideBioAfterLoading = false
    
    private var savedNameColor: UIColor?
    private var savedLoginColor: UIColor?
    private var savedBioColor: UIColor?
    
    private var avatarRetryCount = 0
    private let maxAvatarRetryCount = 3
    
    private var avatarURLFallbackTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 1)
        
        setupSubviews()
        setupConstraints()
        logoutButton.addTarget(self, action: #selector(didTapLogoutButton), for: .touchUpInside)
        
        updateLogoutVisibility()
        
        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAvatar()
        }
        
        startAvatarSkeletonIfNeeded()
        startFixedTextSkeletonsIfNeeded()
        
        updateAvatar()
        if let profile = profileService.profile {
            updateProfile(with: profile)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        startAvatarSkeletonIfNeeded()
        startFixedTextSkeletonsIfNeeded()
    }
    
    deinit {
        avatarURLFallbackTimer?.invalidate()
        if let t = profileImageServiceObserver {
            NotificationCenter.default.removeObserver(t)
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
    
    private func onStateChange() {
        updateLogoutVisibility()
        stopSkeletonIfReady()
    }
    
    private func updateLogoutVisibility() {
        logoutButton.isHidden = isLoading
    }
    
    private func stopSkeletonIfReady() {
        guard isProfileLoaded && isAvatarLoaded else { return }
        
        stopTextGradients()
        stopAvatarGradient()
        
        removeAllLoadingGradients(from: view)
        
        nameLabel.textColor  = savedNameColor  ?? .white
        loginNameLabel.textColor = savedLoginColor
        ?? UIColor(red: 0xAE/255, green: 0xAF/255, blue: 0xB4/255, alpha: 1)
        descriptionLabel.textColor = savedBioColor ?? .white
        
        descriptionLabel.isHidden = shouldHideBioAfterLoading
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    private func removeAllLoadingGradients(from root: UIView) {
        for sub in root.subviews {
            if let g = sub as? LoadingGradientView { g.stop() }
            removeAllLoadingGradients(from: sub)
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
            width: SkeletonLayout.nameWidth,
            height: SkeletonLayout.height,
            cornerRadius: SkeletonLayout.radius,
            align: .center
        )
        loginGradient = loginNameLabel.addLoadingGradientFixedWidth(
            width: SkeletonLayout.loginWidth,
            height: SkeletonLayout.height,
            cornerRadius: SkeletonLayout.radius,
            align: .center
        )
        bioGradient   = descriptionLabel.addLoadingGradientFixedWidth(
            width: SkeletonLayout.bioWidth,
            height: SkeletonLayout.height,
            cornerRadius: SkeletonLayout.radius,
            align: .center
        )
    }
    
    private func stopTextGradients() {
        nameGradient?.stop();   nameGradient = nil
        loginGradient?.stop();  loginGradient = nil
        bioGradient?.stop();    bioGradient = nil
        
        nameHeightWhenSkeleton?.isActive = false
        nameHeightWhenSkeleton = nil
    }
    
    private func stopAvatarGradient() {
        avatarGradient?.stop(); avatarGradient = nil
    }
    
    @objc private func didTapLogoutButton() {
        presentLogoutAlert()
    }
    
    private func updateProfile(with profile: Profile) {
        nameLabel.text = profile.name
        loginNameLabel.text = profile.loginName
        
        let bioText = profile.bio?.trimmingCharacters(in: .whitespacesAndNewlines)
        shouldHideBioAfterLoading = (bioText?.isEmpty ?? true)
        descriptionLabel.text = (bioText?.isEmpty == false) ? bioText : nil
        
        isProfileLoaded = true
        stopSkeletonIfReady()
    }
    
    private func updateAvatar() {
        if let urlString = ProfileImageService.shared.avatarURL,
           let url = URL(string: urlString) {
            
            avatarURLFallbackTimer?.invalidate(); avatarURLFallbackTimer = nil
            
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
                    self.stopSkeletonIfReady()
                case .failure:
                    self.retryUpdateAvatarOrFinish()
                }
            }
            return
        }
        
        if avatarURLFallbackTimer == nil {
            avatarURLFallbackTimer = Timer.scheduledTimer(withTimeInterval: 6, repeats: false) { [weak self] _ in
                guard let self else { return }
                self.avatarImageView.image = UIImage(named: "Avatar")
                self.isAvatarLoaded = true
                self.stopSkeletonIfReady()
            }
        }
    }
    
    private func retryUpdateAvatarOrFinish() {
        if avatarRetryCount < maxAvatarRetryCount {
            avatarRetryCount += 1
            let delay = pow(2.0, Double(avatarRetryCount - 1)) // 1, 2, 4 сек
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.updateAvatar()
            }
        } else {
            avatarImageView.image = UIImage(named: "Avatar")
            isAvatarLoaded = true
            stopSkeletonIfReady()
        }
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
            self?.performLogout()
        }
        let no  = UIAlertAction(title: "Нет", style: .default, handler: nil)
        alert.addAction(yes)
        alert.addAction(no)
        alert.preferredAction = no
        
        present(alert, animated: true)
    }
    
    private func performLogout() {
        ProfileLogoutService.shared.logout()
        
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("No key window")
            return
        }
        window.rootViewController = SplashViewController()
        window.makeKeyAndVisible()
    }
}










