import UIKit
import Kingfisher

final class ImagesListViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!

    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    private let imagesService = ImagesListService.shared
    private var photos: [Photo] = []

    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView.estimatedRowHeight = 200

        NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: imagesService,
            queue: .main
        ) { [weak self] _ in
            self?.updateTableViewAnimated()
        }

        imagesService.fetchPhotosNextPage()
    }

    private func updateTableViewAnimated() {
        let oldCount = photos.count
        let newCount = imagesService.photos.count

        if newCount == oldCount {
            photos = imagesService.photos
            if let visible = tableView.indexPathsForVisibleRows, !visible.isEmpty {
                tableView.reloadRows(at: visible, with: .none)
            } else {
                tableView.reloadData()
            }
            return
        }

        guard newCount >= oldCount else {
            photos = imagesService.photos
            tableView.reloadData()
            return
        }

        photos = imagesService.photos
        let inserted = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
        tableView.performBatchUpdates {
            tableView.insertRows(at: inserted, with: .automatic)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier,
           let vc = segue.destination as? SingleImageViewController,
           let indexPath = sender as? IndexPath {
            vc.imageURL = URL(string: photos[indexPath.row].largeImageURL)
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }

    private func configure(_ cell: ImagesListCell, at indexPath: IndexPath) {
        cell.delegate = self
        let photo = photos[indexPath.row]
        cell.configure(with: photo, dateFormatter: dateFormatter)
    }
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { photos.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        guard let imageCell = cell as? ImagesListCell else { return UITableViewCell() }
        configure(imageCell, at: indexPath)
        return imageCell
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let p = photos[indexPath.row]
        let insets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let width = tableView.bounds.width - insets.left - insets.right
        let scale = width / max(p.size.width, 1)
        return max(p.size.height * scale + insets.top + insets.bottom, 44)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == photos.count {
            imagesService.fetchPhotosNextPage()
        }
    }
}

extension ImagesListViewController: ImagesListCellDelegate {
    func imagesListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = photos[indexPath.row]
        let newLike = !photo.isLiked

        UIBlockingProgressHUD.show()
        imagesService.changeLike(photoId: photo.id, isLike: newLike) { [weak self] result in
            guard let self else { return }
            UIBlockingProgressHUD.dismiss()

            switch result {
            case .success:
                self.photos = self.imagesService.photos
                if let visible = self.tableView.cellForRow(at: indexPath) as? ImagesListCell {
                    visible.setIsLiked(self.photos[indexPath.row].isLiked)
                } else {
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
            case .failure:
                if let visible = self.tableView.cellForRow(at: indexPath) as? ImagesListCell {
                    visible.setIsLiked(photo.isLiked) // вернули как было
                }
            }
        }
    }
}
