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
    }

    var model: Model? {
        didSet {
            applyModel()
        }
    }

    let spinnerHeight: CGFloat = 24

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

    init() {
        super.init(frame: .zero)
        setUpUI()
        setUpConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpUI() {
        addSubview(imageView)
        addSubview(spinner)
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
            spinner.heightAnchor.constraint(equalToConstant: spinnerHeight),
            spinner.widthAnchor.constraint(equalToConstant: spinnerHeight)
        ])
    }

    private func applyModel() {
        guard let model else { return }

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
