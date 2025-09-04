import UIKit

final class TabBarController: UITabBarController {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let imagesListViewController = storyboard.instantiateViewController(withIdentifier: "ImagesListViewController") as? ImagesListViewController else {
            assertionFailure("ImagesListViewController not found in storyboard")
            return
        }
        imagesListViewController.presenter = ImagesListPresenter(view: imagesListViewController)
        
        let profileViewController = ProfileViewController()
        profileViewController.presenter = ProfilePresenter(view: profileViewController)
        profileViewController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab_profile_active"),
            selectedImage: nil
        )
        
        self.viewControllers = [imagesListViewController, profileViewController]
    }
}
