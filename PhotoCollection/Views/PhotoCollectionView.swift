//
//  PhotoCollectionView.swift
//  PhotoCollection
//
//  Created by Suguru Tokuda on 5/20/25.
//

import UIKit

class PhotoCollectionView: UICollectionView {
    // MARK: Closures
    var scrolledToEnd: (() -> Void)?

    enum Section: Int {
        case main = 0
        case loading = 1
    }

    enum Item: Hashable {
        case photo(PhotoModel)
        case loading
    }

    struct Model {
        let photos: [PhotoModel]
        let showLoadingIndicator: Bool
    }

    // MARK: Typealias

    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    private var flowLayout = UICollectionViewFlowLayout()
    private var diffableDataSource: DataSource?
    var model: Model? {
        didSet {
            applyModel()
        }
    }
    private let threshold: CGFloat = 12

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

        registerCells()
        diffableDataSource = makeDataSource()
        alwaysBounceVertical = true
        delegate = self
    }

    private func registerCells() {
        register(PhotoCell.self,
                 forCellWithReuseIdentifier: PhotoCell.reuseIdentifier)
        register(LoadingIndicatorCell.self,
                forCellWithReuseIdentifier: LoadingIndicatorCell.reuseIdentifier)
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
            var cell: UICollectionViewCell? = UICollectionViewCell()

            guard let self,
                  let section = Section(rawValue: indexPath.section) else { return cell }

            switch section {
            case .main:
                switch itemIdentifier {
                case .photo(let model):
                    cell = dequeuePhotoViewCell(collectionView, indexPath: indexPath, item: model)
                default:
                    break
                }
                
            case .loading:
                cell = dequeueLoadingIndicatorCell(collectionView, indexPath: indexPath)
            }

            return cell
        }
    }

    private func dequeuePhotoViewCell(_ collectionView: UICollectionView, indexPath: IndexPath, item: PhotoModel) -> PhotoCell? {
        if let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: PhotoCell.reuseIdentifier,
                                 for: indexPath) as? PhotoCell {
            cell.model = PhotoView.Model(url: item.cachedImageURL,
                                         loadingStatus: item.loadingStatus ?? .ready,
                                         isShimmering: item.isPlaceholder ?? false
            )
            return cell
        }

        return nil
    }

    private func dequeueLoadingIndicatorCell(_ collectionView: UICollectionView, indexPath: IndexPath) -> LoadingIndicatorCell? {
        collectionView.dequeueReusableCell(withReuseIdentifier: LoadingIndicatorCell.reuseIdentifier, for: indexPath) as? LoadingIndicatorCell
    }

    private func applyModel() {
        guard let model else { return }

        applySnapshot(photos: model.photos,
                      showLoadingIndicator: model.showLoadingIndicator)
    }

    private func applySnapshot(photos: [PhotoModel], showLoadingIndicator: Bool) {
        guard let diffableDataSource else { return }
        
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(photos.map { .photo($0) })
        let hasPlaceholders = photos.contains(where: { $0.isPlaceholder == true })

        if showLoadingIndicator && hasPlaceholders == false {
            if !snapshot.sectionIdentifiers.contains(.loading) {
                snapshot.appendSections([.loading])
                snapshot.appendItems([.loading], toSection: .loading)
            }
        } else {
            if snapshot.sectionIdentifiers.contains(.loading) {
                snapshot.deleteSections([.loading])
            }
        }

        diffableDataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension PhotoCollectionView: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        if offsetY > contentHeight - frameHeight - threshold {
            scrolledToEnd?()
        }
    }
}

extension PhotoCollectionView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let section = Section(rawValue: indexPath.section) else { return .zero }

        switch section {
        case .main:
            return flowLayout.itemSize
        case .loading:
            return CGSize(width: collectionView.bounds.width, height: 40)
        }
    }
}
