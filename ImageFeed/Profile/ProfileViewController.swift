import UIKit

final class ProfileViewController: UIViewController {

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 35
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "logout_button"), for: .normal)
        button.tintColor = UIColor(red: 0xF5/255.0, green: 0x6B/255.0, blue: 0x6C/255.0, alpha: 1)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 23, weight: .semibold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let loginNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(red: 0xAE/255.0, green: 0xAF/255.0, blue: 0xB4/255.0, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    

    override func viewDidLoad() {
        super.viewDidLoad()

        
        view.backgroundColor = UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 1)
        
        
        
        setupSubviews()
        setupConstraints()
        setupActions()
        configureData()
    }


    private func setupSubviews() {
        view.addSubview(avatarImageView)
        view.addSubview(logoutButton)
        view.addSubview(nameLabel)
        view.addSubview(loginNameLabel)
        view.addSubview(descriptionLabel)
    }



    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
               // 1) Аватарка
               avatarImageView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 32),
               avatarImageView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
               avatarImageView.widthAnchor.constraint(equalToConstant: 70),
               avatarImageView.heightAnchor.constraint(equalToConstant: 70),

               logoutButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
               logoutButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
               logoutButton.widthAnchor.constraint(equalToConstant: 44),
               logoutButton.heightAnchor.constraint(equalToConstant: 44),

               nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
               nameLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
               nameLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),

               loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
               loginNameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
               loginNameLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

               descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8),
               descriptionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
               descriptionLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
           ])
    }

    

    private func setupActions() {
        logoutButton.addTarget(
            self,
            action: #selector(didTapLogoutButton),
            for: .touchUpInside
        )
    }

    @objc
    private func didTapLogoutButton() {
        
        print("Кнопку Logout нажали")
    }

    

    private func configureData() {
        avatarImageView.image = UIImage(named: "Avatar")
        nameLabel.text = "Екатерина Новикова"
        loginNameLabel.text = "@ekaterina_nov"
        descriptionLabel.text = "Hello, World!"
    }

}
