import Foundation
import UIKit

protocol ImagesListView: AnyObject {
    func reloadInsertedRows(oldCount: Int, newCount: Int)
    func reloadVisibleRows()
    func updateLike(at index: Int, isLiked: Bool)
    func setBlockingLoading(_ isLoading: Bool)
}

protocol ImagesListPresenting: AnyObject {
    var itemsCount: Int { get }
    func viewDidLoad()
    func item(at index: Int) -> Photo
    func willDisplayRow(at index: Int)
    func didTapLike(at index: Int)
    func didSelectRow(at index: Int) -> URL?
}

protocol ImagesListServiceProtocol: AnyObject {
    var photos: [Photo] { get }
    static var didChangeNotification: Notification.Name { get }
    func fetchPhotosNextPage()
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void)
}

extension ImagesListService: ImagesListServiceProtocol {}

final class ImagesListPresenter: ImagesListPresenting {
    private weak var view: ImagesListView?
    private let service: ImagesListServiceProtocol
    private var lastCount = 0
    private var observer: NSObjectProtocol?
    
    init(view: ImagesListView, service: ImagesListServiceProtocol = ImagesListService.shared) {
        self.view = view
        self.service = service
    }
    
    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    var itemsCount: Int { service.photos.count }
    
    func viewDidLoad() {
        observer = NotificationCenter.default.addObserver(
            forName: type(of: service).didChangeNotification,
            object: service,
            queue: .main
        ) { [weak self] _ in self?.applyDiff() }
        service.fetchPhotosNextPage()
    }
    
    func item(at index: Int) -> Photo { service.photos[index] }
    
    func willDisplayRow(at index: Int) {
        if index + 1 >= service.photos.count { service.fetchPhotosNextPage() }
    }
    
    func didTapLike(at index: Int) {
        let photo = service.photos[index]
        let newLike = !photo.isLiked
        view?.setBlockingLoading(true)
        service.changeLike(photoId: photo.id, isLike: newLike) { [weak self] result in
            guard let self else { return }
            self.view?.setBlockingLoading(false)
            switch result {
            case .success:
                let updated = self.service.photos[index].isLiked
                self.view?.updateLike(at: index, isLiked: updated)
            case .failure:
                self.view?.updateLike(at: index, isLiked: photo.isLiked)
            }
        }
    }
    
    func didSelectRow(at index: Int) -> URL? {
        URL(string: service.photos[index].largeImageURL)
    }
    
    private func applyDiff() {
        let old = lastCount
        let new = service.photos.count
        lastCount = new
        if new == old { view?.reloadVisibleRows() }
        else if new > old { view?.reloadInsertedRows(oldCount: old, newCount: new) }
        else { view?.reloadInsertedRows(oldCount: 0, newCount: new) }
    }
}
