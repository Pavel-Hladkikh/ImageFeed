import UIKit
import ProgressHUD

final class UIBlockingProgressHUD {
    
    private static var window: UIWindow? {
        return UIApplication.shared.windows.first
    }
    
    static func show() {
        assert(Thread.isMainThread)
        window?.isUserInteractionEnabled = false
        ProgressHUD.animate()
    }
    
    static func dismiss() {
        assert(Thread.isMainThread)
        ProgressHUD.dismiss()
        window?.isUserInteractionEnabled = true
    }
}
