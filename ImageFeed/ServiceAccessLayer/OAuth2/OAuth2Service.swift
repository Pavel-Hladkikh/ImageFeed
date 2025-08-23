import Foundation

enum AuthServiceError: Error {
    case invalidRequest
}

final class OAuth2Service {
    
    static let shared = OAuth2Service()
    private init() {}
    
    private let tokenStorage = OAuth2TokenStorage.shared
    private let urlSession = URLSession.shared
    
    private var task: URLSessionTask?
    private var lastCode: String?
    
    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread, "fetchOAuthToken must be called on main thread")
        
        guard lastCode != code else {
            print("[OAuth2Service.fetchOAuthToken]: duplicate request with same code: \(code)")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }
        
        task?.cancel()
        lastCode = code
        
        guard let request = makeOAuthTokenRequest(code: code) else {
            print("[OAuth2Service.fetchOAuthToken]: failed to build request for code: \(code)")
            completion(.failure(NetworkError.invalidRequest))
            lastCode = nil
            return
        }
        
        let newTask = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            guard let self else { return }
            
            switch result {
            case .success(let body):
                let token = body.accessToken
                self.tokenStorage.token = token
                print("[OAuth2Service.fetchOAuthToken]: successfully received token")
                completion(.success(token))
                
            case .failure(let error):
                print("[OAuth2Service.fetchOAuthToken]: failed with error: \(error.localizedDescription), code: \(code)")
                completion(.failure(error))
            }
            
            self.task = nil
            self.lastCode = nil
        }
        
        self.task = newTask
        newTask.resume()
    }
    
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let url = URL(string: "https://unsplash.com/oauth/token") else {
            print("[OAuth2Service.makeOAuthTokenRequest]: invalid URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "client_id": Constants.accessKey,
            "client_secret": Constants.secretKey,
            "redirect_uri": Constants.redirectURI,
            "code": code,
            "grant_type": "authorization_code"
        ]
        
        let bodyString = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        return request
    }
}

