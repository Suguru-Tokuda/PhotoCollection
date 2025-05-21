//
//  PhotoCellCollectionViewCell.swift
//  PhotoCollection
//
//  Created by Suguru Tokuda on 5/20/25.
//

import UIKit

class PhotoCellCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "PhotoCellCollectionViewCell"

    var model: PhotoView.Model? {
        didSet {
            applyModel()
        }
    }

    // MARK: UI Components
    private let photoView: PhotoView = {
        let photoView = PhotoView()
        photoView.translatesAutoresizingMaskIntoConstraints = false
        return photoView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpUI()
        setUpConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpUI() {
        contentView.backgroundColor = .lightGray.withAlphaComponent(0.5)
        contentView.addSubview(photoView)
    }

    private func setUpConstraints() {
        NSLayoutConstraint.activate([
            photoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            photoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            photoView.topAnchor.constraint(equalTo: contentView.topAnchor),
            photoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    private func applyModel() {
        guard let model else { return }

        photoView.model = model
    }
}
