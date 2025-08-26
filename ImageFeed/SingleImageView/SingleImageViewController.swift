import UIKit
import Kingfisher

final class SingleImageViewController: UIViewController {
    
    var imageURL: URL?
    
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 1)
        
        imageView.translatesAutoresizingMaskIntoConstraints = true
        
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 3.0
        
        loadFullImage()
    }
    
    @IBAction private func didTapBackButton() {
        dismiss(animated: true)
    }
    
    @IBAction private func didTapShareButton(_ sender: UIButton) {
        guard let image = imageView.image else { return }
        let share = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(share, animated: true)
    }
    
    private func loadFullImage() {
        guard let url = imageURL else { return }
        
        UIBlockingProgressHUD.show()
        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(with: url, options: [.transition(.fade(0.25))]) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            guard let self else { return }
            
            switch result {
            case .success(let value):
                self.imageView.image = value.image
                self.imageView.frame.size = value.image.size
                self.rescaleAndCenterAspectFill(image: value.image)
            case .failure:
                self.showError()
            }
        }
    }
    
    private func showError() {
        let alert = UIAlertController(
            title: "Что-то пошло не так",
            message: "Попробовать ещё раз?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Не надо", style: .cancel))
        alert.addAction(UIAlertAction(title: "Повторить", style: .default, handler: { [weak self] _ in
            self?.loadFullImage()
        }))
        present(alert, animated: true)
    }
    
    private func rescaleAndCenterAspectFill(image: UIImage) {
        view.layoutIfNeeded()
        
        let visible = scrollView.bounds.size
        let img = image.size
        
        let hScale = visible.width / img.width
        let vScale = visible.height / img.height
        let targetScale = min(scrollView.maximumZoomScale,
                              max(scrollView.minimumZoomScale, max(hScale, vScale)))
        
        scrollView.setZoomScale(targetScale, animated: false)
        scrollView.layoutIfNeeded()
        
        centerContent()
    }
    
    private func centerContent() {
        let bounds = scrollView.bounds.size
        let content = scrollView.contentSize
        
        let insetX = max(0, (bounds.width  - content.width)  / 2)
        let insetY = max(0, (bounds.height - content.height) / 2)
        
        scrollView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
    }
}

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent()
    }
}
