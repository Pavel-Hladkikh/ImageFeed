import Foundation

enum ProfileServiceError: Error {
    case invalidRequest
}

struct ProfileResult: Decodable {
    let username: String
    let firstName: String?
    let lastName: String?
    let bio: String?
    
    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName  = "last_name"
        case bio
    }
}

struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?
}

final class ProfileService {
    
    static let didChangeNotification = Notification.Name("ProfileService.didChange")
    
    static let shared = ProfileService()
    private init() {}
    
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastToken: String?
    
    private(set) var profile: Profile?
    
    func reset() {
        task?.cancel()
        task = nil
        lastToken = nil
        profile = nil
    }
    
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread, "fetchProfile must be called on main thread")
        
        guard lastToken != token else {
            completion(.failure(ProfileServiceError.invalidRequest))
            return
        }
        
        task?.cancel()
        lastToken = token
        
        guard let request = makeProfileRequest(token: token) else {
            completion(.failure(NetworkError.invalidRequest))
            lastToken = nil
            return
        }
        
        let newTask = urlSession.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            guard let self else { return }
            
            switch result {
            case .success(let dto):
                let profile = self.makeProfile(from: dto)
                self.profile = profile
                
                NotificationCenter.default.post(
                    name: ProfileService.didChangeNotification,
                    object: self
                )
                
                completion(.success(profile))
                
            case .failure(let error):
                completion(.failure(error))
            }
            
            self.task = nil
            self.lastToken = nil
        }
        
        self.task = newTask
        newTask.resume()
    }
    
    private func makeProfile(from dto: ProfileResult) -> Profile {
        let fullName = [dto.firstName, dto.lastName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        return Profile(
            username: dto.username,
            name: fullName,
            loginName: "@\(dto.username)",
            bio: dto.bio
        )
    }
    
    private func makeProfileRequest(token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/me") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}


