@testable import ImageFeed
import UIKit
import Foundation

final class ImagesListPresenterSpy: ImagesListPresenting {
    var items: [Photo] = []
    var itemsCount: Int { items.count }

    private(set) var viewDidLoadCalls = 0
    private(set) var willDisplayRows: [Int] = []
    private(set) var didTapLikes: [Int] = []
    private(set) var didSelectRows: [Int] = []

    func viewDidLoad() { viewDidLoadCalls += 1 }
    func item(at index: Int) -> Photo { items[index] }
    func willDisplayRow(at index: Int) { willDisplayRows.append(index) }
    func didTapLike(at index: Int) { didTapLikes.append(index) }
    func didSelectRow(at index: Int) -> URL? {
        didSelectRows.append(index)
        return URL(string: "https://example.com")
    }
}

