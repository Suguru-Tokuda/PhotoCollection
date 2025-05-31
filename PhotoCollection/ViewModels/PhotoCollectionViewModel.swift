//
//  PhotoCollectionViewModel.swift
//  PhotoCollection
//
//  Created by Suguru Tokuda on 5/19/25.
//

import Combine
import Foundation

enum LoadingStatus {
    case ready
    case loading
    case loaded
}

enum Query {
    init?(rawValue: String) {
        switch rawValue {
        case "dogs":
            self = .dogs
        case "cats":
            self = .cats
        default:
            self = .search(rawValue)
        }
    }
    
    case dogs
    case cats
    case search(String)

    var rawValue: String {
        switch self {
        case .dogs:
            return "dogs"
        case .cats:
            return "cats"
        case .search(let searchKeyword):
            return searchKeyword
        }
    }
}

class PhotoCollectionViewModel {
    private var query: Query?
    private var pageNumber = 1
    private let perPage = 21
    private var fetchNext = true
    private var batchCaching: Bool
    private var cancellables = Set<AnyCancellable>()
    private var resetTask: Task<Void, Never>?

    // Publishers
    var loadingStatus = CurrentValueSubject<LoadingStatus, Never>(.ready)
    var photosPublisher = CurrentValueSubject<[PhotoModel], Never>([])
    var searchPublisher = PassthroughSubject<String, Never>()
    var errorPublisher = PassthroughSubject<Error, Never>()

    // Dependencies
    private let photoService: PhotoServiceProtocol
    private let imageCachingManager: ImageCachingManaging
    private let photoStorage: PhotoStorageProtocol
    private let cacheTaskStore: CacheTaskStoreProtocol

    init(photoService: PhotoServiceProtocol = PhotoSerice(),
         imageCachingManager: ImageCachingManaging = ImageCachingManager(),
         photoStorage: PhotoStorageProtocol = PhotoStorage(),
         cacheTaskStore: CacheTaskStoreProtocol = CacheTaskStore(),
         batchCaching: Bool = false,
         query: Query? = nil) {
        self.photoService = photoService
        self.imageCachingManager = imageCachingManager
        self.photoStorage = photoStorage
        self.cacheTaskStore = cacheTaskStore
        self.batchCaching = batchCaching
        self.query = query

        addSubscriptions()
    }

    deinit {
        removeSubscriptions()
        Task { [weak self] in
            await self?.cacheTaskStore.removeAll()
        }
    }

    private func addSubscriptions() {
        searchPublisher
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                guard let self else { return }
                
                resetTask?.cancel()

                resetTask = Task(priority: .userInitiated) { [weak self] in
                    guard let self else { return }

                    await reset()
                    query = .search(searchText)
                }
            }
            .store(in: &cancellables)
    }

    private func removeSubscriptions() {
        cancellables.removeAll()
    }

    func getPhotos() async {
        guard let query,
              fetchNext,
              loadingStatus.value == .ready else { return }
        
        do {
            let photos = await photoStorage.getPhotos()
            if photos.isEmpty {
                var placeholders: [PhotoModel] = []

                for _ in 0..<perPage {
                    placeholders.append(PhotoModel(id: UUID().uuidString, isPlaceholder: true))
                }
                
                await addPhotos(placeholders)
            }

            loadingStatus.send(.loading)
            guard let photoResponseModel = try await photoService.fetchPhotos(query: query.rawValue,
                                                                              pageNumber: pageNumber,
                                                                              perPage: perPage) else {
                return
            }
            await handleResponse(response: photoResponseModel)
            loadingStatus.send(.ready)
        } catch {
            loadingStatus.send(.ready)
            errorPublisher.send(error)
        }
    }

    private func handleResponse(response: PhotosResponseModel) async {
        guard !response.photos.isEmpty else { return }

        if (pageNumber + 1) < response.pages {
            pageNumber += 1
        }

        fetchNext = pageNumber < response.pages

        await photoStorage.removePhotos(where: { $0.isPlaceholder == true })

        // Do async image caching *after* updating map and sending value
        if batchCaching {
            do {
                let cachedPhotos = try await self.cacheImages(photoModels: response.photos)
                await addPhotos(cachedPhotos)
            } catch {
                errorPublisher.send(error)
            }
        } else {
            await addPhotos(response.photos)
            for photoModel in response.photos {
                if await cacheTaskStore.task(for: photoModel.id) == nil {
                    let cacheTask = Task(priority: .userInitiated) { [weak self] in
                        guard let self else { return }
                        
                        await cacheImage(photoModel: photoModel)
                        await cacheTaskStore.remove(for: photoModel.id)
                    }
                    
                    await cacheTaskStore.add(task: cacheTask, for: photoModel.id)
                }
            }
        }
    }

    private func cacheImage(photoModel: PhotoModel) async {
        guard let index = await photoStorage.getIndex(photoModel.id),
              let thumbnailImageURL = photoModel.thumbnailImageURL else { return }

        var photoModel = photoModel
        guard let url = URL(string: thumbnailImageURL) else { return }

        do {
            guard let cachedImageURL = try await imageCachingManager.cacheImage(for: url) else { return }
            photoModel.cachedImageURL = cachedImageURL
            photoModel.loadingStatus = .loaded

            await updatePhotos(index: index, photo: photoModel)
        } catch {
        }
    }

    private func updatePhotos(index: Int, photo: PhotoModel) async {
        await photoStorage.updatePhoto(at: index, with: photo)
        let updated = await photoStorage.getPhotos()
        photosPublisher.send(updated)
    }

    private func addPhotos(_ photos: [PhotoModel]) async {
        await photoStorage.addPhotos(newPhotos: photos)
        let updated = await photoStorage.getPhotos()
        photosPublisher.send(updated)
    }

    private func cacheImages(photoModels: [PhotoModel]) async throws -> [PhotoModel] {
        var retVal: [PhotoModel] = []
        try await withThrowingTaskGroup(of: PhotoModel?.self) { [weak self] group in
            guard let self else { return }

            photoModels.forEach { photoModel in
                guard let thumbnailImageURL = photoModel.thumbnailImageURL,
                      let url = URL(string: thumbnailImageURL) else { return }

                group.addTask { [weak self] in
                    guard let self else { return nil }
                    
                    if let cachedImageURL = try await imageCachingManager.cacheImage(for: url) {
                        var photoModel = photoModel
                        photoModel.cachedImageURL = cachedImageURL
                        photoModel.loadingStatus = .loaded
                        return photoModel
                    } else {
                        return nil
                    }
                }
            }

            for try await result in group {
                if let photoModel = result {
                    retVal.append(photoModel)
                }
            }
        }

        return retVal
    }

    func reset() async {
        query = nil
        await photoStorage.removeAll()
        photosPublisher.send([])
        loadingStatus.send(.ready)
    }
}
