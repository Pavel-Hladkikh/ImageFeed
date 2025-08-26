import UIKit
import Kingfisher

protocol ImagesListCellDelegate: AnyObject {
    func imagesListCellDidTapLike(_ cell: ImagesListCell)
}

final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"

    @IBOutlet private weak var cellImageView: UIImageView!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var likeButton: UIButton!

    weak var delegate: ImagesListCellDelegate?

    private var loadingGradient: LoadingGradientView?

    override func awakeFromNib() {
        super.awakeFromNib()
        cellImageView.layer.cornerRadius = 16
        cellImageView.clipsToBounds = true
        likeButton.setTitle(nil, for: .normal)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cellImageView.kf.cancelDownloadTask()
        cellImageView.image = nil
        dateLabel.text = nil
        likeButton.setImage(nil, for: .normal)
        likeButton.isEnabled = true
        stopGradient()
    }

    @IBAction private func likeButtonTapped(_ sender: UIButton) {
        sender.isEnabled = false
        delegate?.imagesListCellDidTapLike(self)
    }

    func configure(with photo: Photo, dateFormatter: DateFormatter) {
        
        dateLabel.text = photo.createdAt.map { dateFormatter.string(from: $0) } ?? "—"

        startGradientIfNeeded()

        let placeholder = UIImage(named: "Stub")
        cellImageView.kf.indicatorType = .activity

        if let url = URL(string: photo.thumbImageURL) {
            cellImageView.kf.setImage(with: url, placeholder: placeholder, options: [.transition(.fade(0.25))]) { [weak self] result in
                guard let self else { return }
                self.stopGradient()
                if case .failure = result { self.cellImageView.image = placeholder }
            }
        } else {
            stopGradient()
            cellImageView.image = placeholder
        }

        setIsLiked(photo.isLiked)
    }

    func setIsLiked(_ isLiked: Bool) {
        let img = isLiked ? UIImage(named: "likeButtonOn") : UIImage(named: "likeButtonOff")
        likeButton.setImage(img, for: .normal)
        likeButton.isEnabled = true
    }

    private func startGradientIfNeeded() {
        guard loadingGradient == nil else { return }
        loadingGradient = cellImageView.addLoadingGradient(cornerRadius: 16)
    }

    private func stopGradient() {
        loadingGradient?.stop()
        loadingGradient = nil
    }
}
