//
//  PhotoCollectionViewController.swift
//  SwiftConcurrencyDemo
//
//  Created by Suguru Tokuda on 5/19/25.
//

import Combine
import UIKit

class PhotoCollectionViewController: UIViewController {
    private var viewModel: PhotoCollectionViewModel
    private var subscriptions = Set<AnyCancellable>()
    private var photoCollectionView: PhotoCollectionView

    private var searchEnabled: Bool
    
    init(allowBatchCaching: Bool = false, query: Query? = nil, searchEnabled: Bool = false) {
        viewModel = PhotoCollectionViewModel(batchCaching: allowBatchCaching, query: query)
        photoCollectionView = PhotoCollectionView()
        self.searchEnabled = searchEnabled
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        addSubscriptions()

        if !searchEnabled {
            Task { [weak self] in
                await self?.viewModel.getPhotos()
            }            
        }
    }

    deinit {
        removeSubscriptions()
    }

    private func setupUI() {
        photoCollectionView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(photoCollectionView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            photoCollectionView.topAnchor.constraint(equalTo: view.topAnchor),
            photoCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            photoCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            photoCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func addSubscriptions() {
        viewModel
            .photosPublisher
            .combineLatest(viewModel.loadingStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self else { return }

                let hasPlaceholder = value.0.contains(where: { $0.isPlaceholder == true })

                photoCollectionView.isScrollEnabled = !hasPlaceholder
                photoCollectionView.alwaysBounceVertical = !hasPlaceholder

                photoCollectionView.model = PhotoCollectionView.Model(
                    photos: value.0,
                    showLoadingIndicator: value.1 == .loading
                )
            }
            .store(in: &subscriptions)
        
        viewModel
            .errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                
            }
            .store(in: &subscriptions)

        photoCollectionView.scrolledToEnd = { [weak self] in
            Task(priority: .userInitiated) {
                await self?.viewModel.getPhotos()
            }            
        }
    }

    private func removeSubscriptions() {
        subscriptions.removeAll()
    }
}
