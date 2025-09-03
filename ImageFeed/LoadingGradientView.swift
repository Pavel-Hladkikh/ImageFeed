import UIKit

final class LoadingGradientView: UIView {
    
    private let animKey = "locationsChange"
    override class var layerClass: AnyClass { CAGradientLayer.self }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        isUserInteractionEnabled = false
        backgroundColor = .clear
        guard let g = layer as? CAGradientLayer else { return }
        g.colors = [
            UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1).cgColor,
            UIColor(red: 0.531, green: 0.533, blue: 0.553, alpha: 1).cgColor,
            UIColor(red: 0.431, green: 0.433, blue: 0.453, alpha: 1).cgColor
        ]
        g.locations = [0, 0.1, 0.3]
        g.startPoint = CGPoint(x: 0, y: 0.5)
        g.endPoint   = CGPoint(x: 1, y: 0.5)
        g.masksToBounds = true
    }
    
    func start() {
        guard layer.animation(forKey: animKey) == nil else { return }
        let a = CABasicAnimation(keyPath: "locations")
        a.fromValue = [0, 0.1, 0.3]
        a.toValue   = [0, 0.8, 1]
        a.duration = 1.0
        a.repeatCount = .infinity
        a.isRemovedOnCompletion = false
        layer.add(a, forKey: animKey)
    }
    
    func stop() {
        layer.removeAnimation(forKey: animKey)
        removeFromSuperview()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        (layer as? CAGradientLayer)?.frame = bounds
    }
}

extension UIView {
    enum VerticalAlign { case center, top }
    
    @discardableResult
    func addLoadingGradient(cornerRadius: CGFloat = 0) -> LoadingGradientView {
        let v = LoadingGradientView(frame: bounds)
        v.translatesAutoresizingMaskIntoConstraints = false
        addSubview(v)
        NSLayoutConstraint.activate([
            v.leadingAnchor.constraint(equalTo: leadingAnchor),
            v.trailingAnchor.constraint(equalTo: trailingAnchor),
            v.topAnchor.constraint(equalTo: topAnchor),
            v.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        if cornerRadius > 0 { v.layer.cornerRadius = cornerRadius }
        v.start()
        return v
    }
    
    @discardableResult
    func addLoadingGradientFixedWidth(
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat = 9,
        align: VerticalAlign = .center
    ) -> LoadingGradientView {
        let v = LoadingGradientView(frame: .zero)
        v.translatesAutoresizingMaskIntoConstraints = false
        addSubview(v)
        
        var cs: [NSLayoutConstraint] = [
            v.leadingAnchor.constraint(equalTo: leadingAnchor),
            v.widthAnchor.constraint(equalToConstant: width),
            v.heightAnchor.constraint(equalToConstant: height)
        ]
        switch align {
        case .center:
            cs.append(v.centerYAnchor.constraint(equalTo: centerYAnchor))
        case .top:
            cs.append(v.topAnchor.constraint(equalTo: topAnchor))
        }
        NSLayoutConstraint.activate(cs)
        
        v.layer.cornerRadius = cornerRadius
        v.start()
        return v
    }
}





