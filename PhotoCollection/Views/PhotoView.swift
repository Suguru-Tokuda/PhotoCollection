//
//  PhotoView.swift
//  PhotoCollection
//
//  Created by Suguru Tokuda on 5/20/25.
//

import UIKit

class PhotoView: UIView {
    struct Model {
        let url: URL?
        let loadingStatus: LoadingStatus?
        let isShimmering: Bool?
    }

    var model: Model? {
        didSet {
            applyModel()
        }
    }

    // MARK: UI Components
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    private let shimmerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .lightGray.withAlphaComponent(0.5)
        return view
    }()
    private let shimmerLayer = CAGradientLayer()

    init() {
        super.init(frame: .zero)
        setUpUI()
        setUpConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shimmerLayer.frame = shimmerView.bounds
    }
    
    private func setUpUI() {
        addSubview(imageView)
        addSubview(spinner)
        addSubview(shimmerView)
        shimmerView.layer.addSublayer(shimmerLayer)
        shimmerView.isHidden = true
    }

    private func setUpConstraints() {
        NSLayoutConstraint.activate([
            // image view
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),

            shimmerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            shimmerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            shimmerView.topAnchor.constraint(equalTo: topAnchor),
            shimmerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func applyModel() {
        guard let model else { return }

        if model.isShimmering == true {
            startShimmer()
        } else {
            stopShimmer()
            switch model.loadingStatus {
            case .loaded:
                guard let url = model.url else {
                    return
                }

                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    spinner.stopAnimating()
                    spinner.isHidden = true
                    imageView.setImage(from: url)
                }
            default:
                spinner.startAnimating()
                spinner.isHidden = false
            }

        }
    }

    private func startShimmer() {
        guard let isShimmering = model?.isShimmering,
              isShimmering else { return }

        shimmerView.isHidden = false

        shimmerLayer.colors = [
            UIColor.lightGray.withAlphaComponent(0.3).cgColor,
            UIColor.white.withAlphaComponent(0.6).cgColor,
            UIColor.lightGray.withAlphaComponent(0.3).cgColor
        ]

        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint = CGPoint(x: 1, y: 0.5)
        shimmerLayer.locations = [0, 0.5, 1]

        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.duration = 1.2
        animation.repeatCount = .infinity

        shimmerLayer.add(animation, forKey: "shimmer")
    }

    private func stopShimmer() {
        shimmerLayer.removeAnimation(forKey: "shimmer")
        shimmerView.isHidden = true
    }
}
