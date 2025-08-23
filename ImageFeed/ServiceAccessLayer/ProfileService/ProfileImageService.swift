import Foundation

struct UserResult: Codable {
    let profileImage: ProfileImage
    
    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

struct ProfileImage: Codable {
    let small: String
}

final class ProfileImageService {
    static let shared = ProfileImageService()
    private init() {}
    
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")
    
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastUsername: String?
    
    private(set) var avatarURL: String?
    
    func fetchProfileImageURL(username: String, _ completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread, "fetchProfileImageURL must be called on main thread")
        
        guard lastUsername != username else {
            print("[ProfileImageService.fetchProfileImageURL]: duplicate request for username: \(username)")
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        task?.cancel()
        lastUsername = username
        
        guard let request = makeProfileImageRequest(username: username) else {
            print("[ProfileImageService.fetchProfileImageURL]: failed to build request for username: \(username)")
            completion(.failure(NetworkError.invalidRequest))
            lastUsername = nil
            return
        }
        
        let newTask = urlSession.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            guard let self else { return }
            
            switch result {
            case .success(let dto):
                let url = dto.profileImage.small
                self.avatarURL = url
                completion(.success(url))
                
                NotificationCenter.default.post(
                    name: ProfileImageService.didChangeNotification,
                    object: self,
                    userInfo: ["URL": url]
                )
                
            case .failure(let error):
                print("[ProfileImageService.fetchProfileImageURL]: network error - \(error.localizedDescription), username: \(username)")
                completion(.failure(error))
            }
            
            self.task = nil
            self.lastUsername = nil
        }
        
        task = newTask
        newTask.resume()
    }
    
    private func makeProfileImageRequest(username: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/users/\(username)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = OAuth2TokenStorage.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}


