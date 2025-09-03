import Foundation

struct UrlsResult: Decodable {
    let thumb: String
    let full: String
}

struct PhotoResult: Decodable {
    let id: String
    let width: Int
    let height: Int
    let createdAt: String?
    let description: String?
    let likedByUser: Bool
    let urls: UrlsResult

    enum CodingKeys: String, CodingKey {
        case id, width, height, description, urls
        case createdAt   = "created_at"
        case likedByUser = "liked_by_user"
    }
}

typealias PhotosPageResult = [PhotoResult]
