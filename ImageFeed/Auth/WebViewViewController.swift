import UIKit
import WebKit

enum WebViewConstants {
    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
}

protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String)
    func webViewViewControllerDidCancel(_ vc: WebViewViewController)
}

final class WebViewViewController: UIViewController {
    weak var delegate: WebViewViewControllerDelegate?
    
    @IBOutlet private var webView: WKWebView!
    @IBOutlet private var progressView: UIProgressView!
    
    private var estimatedProgressObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("[WebViewViewController.viewDidLoad]: loaded")
        
        webView.navigationDelegate = self
        loadAuthView()
        observeProgress()
    }
    
    private func loadAuthView() {
        guard var urlComponents = URLComponents(string: WebViewConstants.unsplashAuthorizeURLString) else {
            print("[WebViewViewController.loadAuthView]: invalid base URL")
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Constants.accessScope)
        ]
        
        guard let url = urlComponents.url else {
            print("[WebViewViewController.loadAuthView]: failed to build auth URL")
            return
        }
        
        let request = URLRequest(url: url)
        print("[WebViewViewController.loadAuthView]: loading \(url.absoluteString)")
        webView.load(request)
    }
    
    private func observeProgress() {
        estimatedProgressObservation = webView.observe(
            \.estimatedProgress,
             options: []
        ) { [weak self] _, _ in
            self?.updateProgress()
        }
    }
    
    private func updateProgress() {
        let progress = Float(webView.estimatedProgress)
        progressView.progress = progress
        progressView.isHidden = fabs(webView.estimatedProgress - 1.0) <= 0.0001
        print("[WebViewViewController.updateProgress]: \(progress * 100)%")
    }
}

extension WebViewViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let code = code(from: navigationAction) {
            print("[WebViewViewController.decidePolicy]: found auth code: \(code)")
            delegate?.webViewViewController(self, didAuthenticateWithCode: code)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
    
    private func code(from navigationAction: WKNavigationAction) -> String? {
        guard
            let url = navigationAction.request.url,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            print("[WebViewViewController.code]: invalid navigationAction URL")
            return nil
        }
        
        if components.path == "/oauth/authorize/native",
           let queryItems = components.queryItems,
           let code = queryItems.first(where: { $0.name == "code" })?.value {
            return code
        }
        
        return nil
    }
}
