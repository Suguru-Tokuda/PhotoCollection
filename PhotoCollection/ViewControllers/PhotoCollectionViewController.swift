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
            .photos
            .receive(on: DispatchQueue.main)
            .sink { [weak self] photos in
                guard let self else { return }

//                print("new photos sent")
//                photos.enumerated().forEach { (index, photo) in
//                    if photo.loadingStatus != .loaded {
//                        print("\(index) - \(photo.loadingStatus ?? .none)")
//                    }
//                }
                
                photoCollectionView.model = PhotoCollectionView.Model(
                    photos: photos
                )
            }
            .store(in: &subscriptions)
        
        viewModel
            .errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                
            }
            .store(in: &subscriptions)
    }

    private func removeSubscriptions() {
        subscriptions.removeAll()
    }
}
