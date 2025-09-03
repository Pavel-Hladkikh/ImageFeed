import UIKit
import Kingfisher

final class ImagesListViewController: UIViewController, ImagesListView {
    @IBOutlet private var tableView: UITableView!
    
    var presenter: ImagesListPresenting!
    
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    
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
        tableView.accessibilityIdentifier = "ImagesListTable"
        
        presenter.viewDidLoad()
    }
    
    func reloadInsertedRows(oldCount: Int, newCount: Int) {
        if oldCount == 0 {
            tableView.reloadData()
            return
        }
        let inserted = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
        tableView.performBatchUpdates {
            tableView.insertRows(at: inserted, with: .automatic)
        }
    }
    
    func reloadVisibleRows() {
        if let visible = tableView.indexPathsForVisibleRows, !visible.isEmpty {
            tableView.reloadRows(at: visible, with: .none)
        } else {
            tableView.reloadData()
        }
    }
    
    func updateLike(at index: Int, isLiked: Bool) {
        if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ImagesListCell {
            cell.setIsLiked(isLiked)
        } else {
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }
    
    func setBlockingLoading(_ isLoading: Bool) {
        if isLoading {
            UIBlockingProgressHUD.show()
        } else {
            UIBlockingProgressHUD.dismiss()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier,
           let vc = segue.destination as? SingleImageViewController,
           let indexPath = sender as? IndexPath,
           let url = presenter.didSelectRow(at: indexPath.row) {
            vc.imageURL = url
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

extension ImagesListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        presenter.itemsCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        guard let imageCell = cell as? ImagesListCell else { return UITableViewCell() }
        let photo = presenter.item(at: indexPath.row)
        imageCell.delegate = self
        imageCell.configure(with: photo, dateFormatter: dateFormatter)
        return imageCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let p = presenter.item(at: indexPath.row)
        let insets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let width = tableView.bounds.width - insets.left - insets.right
        let scale = width / max(p.size.width, 1)
        return max(p.size.height * scale + insets.top + insets.bottom, 44)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        presenter.willDisplayRow(at: indexPath.row)
    }
}

extension ImagesListViewController: ImagesListCellDelegate {
    func imagesListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        presenter.didTapLike(at: indexPath.row)
    }
}
