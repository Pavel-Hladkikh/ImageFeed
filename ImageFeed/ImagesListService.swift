import Foundation
import CoreGraphics

// Ответ Unsplash на POST/DELETE лайка
struct LikeResponse: Decodable {
    let photo: PhotoResult
}

final class ImagesListService {
    // MARK: - Singleton
    static let shared = ImagesListService()
    private init() {}

    // MARK: - Notifications
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")

    // MARK: - Private
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var likeTask: URLSessionTask?
    private var lastLoadedPage: Int?
    private let perPage = 10

    // Один раз создаём форматтеры, потом переиспользуем
    private lazy var iso8601WithFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private lazy var iso8601Plain: ISO8601DateFormatter = {
        ISO8601DateFormatter()
    }()

    // MARK: - Public state
    private(set) var isLoading = false
    private(set) var photos: [Photo] = []

    // MARK: - Helpers

    func reset() {
        task?.cancel()
        likeTask?.cancel()
        task = nil
        likeTask = nil
        lastLoadedPage = nil
        photos = []
        isLoading = false
    }

    private func parseDate(_ string: String?) -> Date? {
        guard let s = string else { return nil }
        return iso8601WithFractional.date(from: s) ?? iso8601Plain.date(from: s)
    }

    // MARK: - Paging

    func fetchPhotosNextPage() {
        guard !isLoading else { return }

        let nextPage = (lastLoadedPage ?? 0) + 1
        guard let request = makePhotosRequest(page: nextPage, perPage: perPage) else {
            print("[ImagesListService.fetchPhotosNextPage]: invalidRequest page=\(nextPage) perPage=\(perPage)")
            return
        }

        isLoading = true
        task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self else { return }

            switch result {
            case .success(let dtoList):
                let newPhotos: [Photo] = dtoList.map { dto in
                    Photo(
                        id: dto.id,
                        size: CGSize(width: dto.width, height: dto.height),
                        createdAt: self.parseDate(dto.createdAt),
                        welcomeDescription: dto.description,
                        thumbImageURL: dto.urls.thumb,
                        largeImageURL: dto.urls.full,
                        isLiked: dto.likedByUser
                    )
                }

                self.photos.append(contentsOf: newPhotos)

                // Убираем дубликаты по id
                var seen = Set<String>()
                self.photos = self.photos.filter { p in
                    if seen.contains(p.id) { return false }
                    seen.insert(p.id); return true
                }

                self.lastLoadedPage = nextPage

                print("[ImagesListService.fetchPhotosNextPage]: success received=\(dtoList.count) page=\(nextPage) perPage=\(self.perPage) total=\(self.photos.count)")

                NotificationCenter.default.post(
                    name: ImagesListService.didChangeNotification,
                    object: self
                )

            case .failure(let error):
                print("[ImagesListService.fetchPhotosNextPage]: failure \(error.localizedDescription) page=\(nextPage) perPage=\(self.perPage)")
            }

            self.isLoading = false
            self.task = nil
        }
        task?.resume()
    }

    private func makePhotosRequest(page: Int, perPage: Int) -> URLRequest? {
        guard var components = URLComponents(string: "\(Constants.defaultBaseURL)/photos") else { return nil }
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        if let token = OAuth2TokenStorage.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    // MARK: - Likes

    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        assert(Thread.isMainThread)

        likeTask?.cancel()

        guard let request = makeLikeRequest(photoId: photoId, isLike: isLike) else {
            print("[ImagesListService.changeLike]: invalidRequest photoId=\(photoId) isLike=\(isLike)")
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<LikeResponse, Error>) in
            guard let self else { return }

            switch result {
            case .success(let resp):
                let dto = resp.photo
                let updated = Photo(
                    id: dto.id,
                    size: CGSize(width: dto.width, height: dto.height),
                    createdAt: self.parseDate(dto.createdAt),
                    welcomeDescription: dto.description,
                    thumbImageURL: dto.urls.thumb,
                    largeImageURL: dto.urls.full,
                    isLiked: dto.likedByUser
                )

                if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                    self.photos[index] = updated
                }

                print("[ImagesListService.changeLike]: success photoId=\(photoId) isLiked=\(updated.isLiked)")

                NotificationCenter.default.post(
                    name: ImagesListService.didChangeNotification,
                    object: self,
                    userInfo: ["updatedId": photoId]
                )
                completion(.success(()))

            case .failure(let error):
                print("[ImagesListService.changeLike]: failure \(error.localizedDescription) photoId=\(photoId) isLike=\(isLike)")
                completion(.failure(error))
            }

            self.likeTask = nil
        }

        likeTask = task
        task.resume()
    }

    private func makeLikeRequest(photoId: String, isLike: Bool) -> URLRequest? {
        guard let url = URL(string: "/photos/\(photoId)/like", relativeTo: Constants.defaultBaseURL) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        if let token = OAuth2TokenStorage.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}
