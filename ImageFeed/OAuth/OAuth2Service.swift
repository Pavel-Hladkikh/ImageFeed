
import Foundation

final class OAuth2Service {
    
    static let shared = OAuth2Service()
    
    private init() {}
    
    private let tokenStorage = OAuth2TokenStorage.shared
    private var task: URLSessionTask?
    
    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        task?.cancel()
        guard let request = makeOAuthTokenRequest(code: code) else {
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("🛑 Network error:", error)
                    completion(.failure(error))
                    return
                }
                guard
                    let httpResponse = response as? HTTPURLResponse,
                    let data = data
                else {
                    print("🛑 Invalid response or no data")
                    completion(.failure(NetworkError.invalidResponse))
                    return
                }
                if !(200..<300).contains(httpResponse.statusCode) {
                    let rawResponse = String(data: data, encoding: .utf8) ?? "nil"
                    print("🛑 HTTP \(httpResponse.statusCode). Raw body:\n\(rawResponse)")
                    completion(.failure(NetworkError.httpStatusCode(httpResponse.statusCode)))
                    return
                }
                do {
                    let body = try JSONDecoder().decode(OAuthTokenResponseBody.self, from: data)
                    let token = body.accessToken
                    self?.tokenStorage.token = token
                    completion(.success(token))
                } catch {
                    let raw = String(data: data, encoding: .utf8) ?? "nil"
                    print("🛑 JSON decode error:", error)
                    print("📦 Raw response:\n\(raw)")
                    completion(.failure(NetworkError.decodingError(error)))
                }
            }
        }
        task?.resume()
    }
    
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let url = URL(string: "https://unsplash.com/oauth/token") else {
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

