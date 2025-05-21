//
//  PhotoCollectionView.swift
//  PhotoCollection
//
//  Created by Suguru Tokuda on 5/20/25.
//

import UIKit

class PhotoCollectionView: UICollectionView {
    enum Section {
        case main
    }

    struct Model {
        let photos: [PhotoModel]
    }

    // MARK: Typealias

    typealias DataSource = UICollectionViewDiffableDataSource<Section, PhotoModel>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, PhotoModel>

    private var flowLayout = UICollectionViewFlowLayout()
    private var diffableDataSource: DataSource?
    var model: Model? {
        didSet {
            applyModel()
        }
    }

    init() {
        super.init(frame: .zero, collectionViewLayout: flowLayout)
        setUpCollectionView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateItemSize()
    }

    private func setUpCollectionView() {
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumInteritemSpacing = 4
        flowLayout.minimumLineSpacing = 4
        flowLayout.sectionInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)

        register(PhotoCellCollectionViewCell.self,
                 forCellWithReuseIdentifier: PhotoCellCollectionViewCell.reuseIdentifier)
        diffableDataSource = makeDataSource()
        alwaysBounceVertical = true
    }

    private func updateItemSize() {
        let padding: CGFloat = 4
        let itemsPerRow: CGFloat = 3
        let totalPadding = padding * (itemsPerRow + 1)
        let availableWidth = bounds.width
        guard availableWidth > 0 else { return }

        let itemWidth = (availableWidth - totalPadding) / itemsPerRow

        if flowLayout.itemSize.width != itemWidth || flowLayout.itemSize.height != itemWidth {
            flowLayout.itemSize = CGSize(width: itemWidth, height: itemWidth)
            flowLayout.invalidateLayout()
        }
    }

    private func makeDataSource() -> DataSource {
        DataSource(collectionView: self) { [weak self] collectionView, indexPath, itemIdentifier in
            guard let self else { return nil }

            if let cell = dequeuePhotoViewCell(collectionView,
                                               indexPath: indexPath,
                                               item: itemIdentifier) {
                return cell
            }

            return nil
        }
    }

    private func dequeuePhotoViewCell(_ collectionView: UICollectionView, indexPath: IndexPath, item: PhotoModel) -> PhotoCellCollectionViewCell? {
        if let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: PhotoCellCollectionViewCell.reuseIdentifier,
                                 for: indexPath) as? PhotoCellCollectionViewCell {
            cell.model = PhotoView.Model(url: item.cachedImageURL,
                                         loadingStatus: item.loadingStatus ?? .ready)
            return cell
        }

        return nil
    }

    private func applyModel() {
        guard let model else { return }

        applySnapshot(photos: model.photos)
    }

    private func applySnapshot(photos: [PhotoModel]) {
        guard let diffableDataSource else { return }
        
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(photos)
        diffableDataSource.apply(snapshot, animatingDifferences: false)
    }
}
