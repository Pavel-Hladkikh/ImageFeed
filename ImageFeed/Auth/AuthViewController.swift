import UIKit

protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ viewController: AuthViewController)
}

final class AuthViewController: UIViewController {
    
    private let showWebViewSegueIdentifier = "ShowWebView"
    private let oauth2Service = OAuth2Service.shared
    
    weak var delegate: AuthViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackButton()
        print("[AuthViewController.viewDidLoad]: loaded successfully")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewSegueIdentifier {
            guard let webViewViewController = segue.destination as? WebViewViewController else {
                assertionFailure("[AuthViewController.prepare]: failed to cast destination to WebViewViewController")
                return
            }
            
            let authHelper = AuthHelper()
            let webViewPresenter = WebViewPresenter(authHelper: authHelper) 
            webViewViewController.presenter = webViewPresenter
            webViewPresenter.view = webViewViewController
            
            webViewViewController.delegate = self
            print("[AuthViewController.prepare]: segue to WebViewViewController set up")
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    private func configureBackButton() {
        navigationController?.navigationBar.backIndicatorImage = UIImage(named: "nav_back_button")
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "nav_back_button")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = UIColor(named: "ypBlack")
    }
    
    private func showLoginErrorAlert() {
        let alertController = UIAlertController(
            title: "Что-то пошло не так",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alertController, animated: true)
    }
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ viewController: WebViewViewController,
                               didAuthenticateWithCode code: String) {
        print("[AuthViewController.webViewViewController]: received code: \(code)")
        
        viewController.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            UIBlockingProgressHUD.show()
            print("[AuthViewController]: fetching token with code: \(code)")
            
            self.oauth2Service.fetchOAuthToken(code: code) { result in
                UIBlockingProgressHUD.dismiss()
                
                switch result {
                case .success:
                    print("[AuthViewController]: token successfully received")
                    self.delegate?.didAuthenticate(self)
                    
                case .failure(let error):
                    print("[AuthViewController]: token request failed - \(error.localizedDescription)")
                    self.showLoginErrorAlert()
                }
            }
        }
    }
    
    func webViewViewControllerDidCancel(_ viewController: WebViewViewController) {
        print("[AuthViewController.webViewViewControllerDidCancel]: user cancelled auth")
        viewController.dismiss(animated: true)
    }
}
