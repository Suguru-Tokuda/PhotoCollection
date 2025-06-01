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
    private var getPhotosTask: Task<Void, Never>?
    private var clearTask: Task<Void, Never>?

    // MARK: - UI Components

    private var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()
    private var photoCollectionView: PhotoCollectionView
    private lazy var searchBar: SearchBar = {
        let searchBar = SearchBar(model: SearchBar.Model(placeholder: "Search photos"))
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
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
        photoCollectionView.keyboardDismissMode = .interactive
        
        view.addSubview(stackView)

        if searchEnabled {
            searchBar.delegate = self
            stackView.addArrangedSubview(searchBar)
        }

        stackView.addArrangedSubview(photoCollectionView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
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
            guard let self else { return }
            
            getPhotosTask = Task(priority: .userInitiated) { [weak self] in
                await self?.viewModel.getPhotos()
            }
        }
    }
    
    private func removeSubscriptions() {
        subscriptions.removeAll()
        getPhotosTask?.cancel()
    }
}

extension PhotoCollectionViewController: SearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchPublisher.send(searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        viewModel.resetPageNumber()
        getPhotosTask?.cancel()
        getPhotosTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            await viewModel.reset()
            guard let searchText = searchBar.text else { return }

            viewModel.setQuery(text: searchText)
            await viewModel.getPhotos()
        }
    }

    func clearButtonClicked() {
        clearTask?.cancel()
        clearTask = Task { [weak self] in
            self?.searchBar.setText(text: "")
            await self?.viewModel.reset()
        }
    }
}
