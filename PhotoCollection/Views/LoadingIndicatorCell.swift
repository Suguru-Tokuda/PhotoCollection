//
//  LoadingIndicatorCell.swift
//  PhotoCollection
//
//  Created by Suguru Tokuda on 5/21/25.
//

import UIKit

class LoadingIndicatorCell: UICollectionViewCell {
    static let reuseIdentifier = "LoadingIndicatorCell"

    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        spinner.startAnimating()
    }

    private func setupUI() {
        contentView.addSubview(spinner)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}
