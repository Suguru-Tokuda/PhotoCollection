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

enum Query: String {
    case dogs
    case cats
}

class PhotoCollectionViewModel {
    private var query: String?
    private var pageNumber = 1
    private let perPage = 21
    private var fetchNext = true
    private var batchCaching: Bool
    private var batchTasks = Set<Task<Void, Never>>()

    private var queue = DispatchQueue(
        label: "com.PhotoCollection.PhotoCollectionViewModelQueueu",
        qos: .userInitiated
    )

    var loadingStatus = CurrentValueSubject<LoadingStatus, Never>(.ready)
    var photos = CurrentValueSubject<[PhotoModel], Never>([])
    private var _photoIndexMap: [String: Int] = [:]
    private var photoIndexMap: [String: Int] {
        get {
            queue.sync { _photoIndexMap }
        }
        set {
            queue.async(flags: .barrier) { [weak self] in
                self?._photoIndexMap = newValue
            }
        }
    }
    
    var errorPublisher = PassthroughSubject<Error, Never>()

    // Dependencies
    private let photoService: PhotoServiceProtocol
    private let imageCachingManager: ImageCachingManaging

    init(photoService: PhotoServiceProtocol = PhotoSerice(),
         imageCachingManager: ImageCachingManaging = ImageCachingManager(),
         batchCaching: Bool = false,
         query: Query? = nil) {
        self.photoService = photoService
        self.imageCachingManager = imageCachingManager
        self.batchCaching = batchCaching
        self.query = query?.rawValue
    }

    func getPhotos() async {
        guard let query,
              fetchNext,
              loadingStatus.value == .ready else { return }
        
        do {
            if photos.value.isEmpty {
                var placeholders: [PhotoModel] = []

                for _ in 0..<perPage {
                    placeholders.append(PhotoModel(id: UUID().uuidString, isPlaceholder: true))
                }

                photos.send(placeholders)
            }

            loadingStatus.send(.loading)
            guard let photoResponseModel = try await photoService.fetchPhotos(query: query,
                                                                              pageNumber: pageNumber,
                                                                              perPage: perPage) else {
                return
            }
            await handleResponse(response: photoResponseModel)
            loadingStatus.send(.ready)
        } catch {
            errorPublisher.send(error)
        }
    }

    private func handleResponse(response: PhotosResponseModel) async {
        guard !response.results.isEmpty else { return }

        if (pageNumber + 1) < response.totalPages {
            pageNumber += 1
        }

        fetchNext = pageNumber <= response.totalPages

        var photos = self.photos.value.filter { $0.isPlaceholder != true }
        var count = photos.count

        // Do async image caching *after* updating map and sending value
        if batchCaching {
            do {
                let cachedPhotos = try await self.cacheImages(photoModels: response.results)
                for cachedPhoto in cachedPhotos {
                    if photoIndexMap[cachedPhoto.id] == nil {
                        photoIndexMap[cachedPhoto.id] = count
                        photos.append(cachedPhoto)
                        count += 1
                    }
                }

                self.photos.send(photos)
            } catch {
                errorPublisher.send(error)
            }
        } else {
            for result in response.results {
                if photoIndexMap[result.id] == nil {
                    photoIndexMap[result.id] = count
                    photos.append(result)
                    count += 1
                }
            }

            self.photos.send(photos)

            for photoModel in response.results {
                Task(priority: .userInitiated) { [weak self] in
                    await self?.cacheImage(photoModel: photoModel)
                }
            }
        }
    }

    private func cacheImage(photoModel: PhotoModel) async {
        guard let index = photoIndexMap[photoModel.id],
              let urls = photoModel.urls else { return }

        var photoModel = photoModel
        guard let url = URL(string: urls.small) else { return }

        do {
            guard let cachedImageURL = try await imageCachingManager.cacheImage(for: url) else { return }
            photoModel.cachedImageURL = cachedImageURL
            photoModel.loadingStatus = .loaded

            updatePhotos(index: index, photo: photoModel)
        } catch {
            print("caching failed \(error)")
        }
    }

    private func updatePhotos(index: Int, photo: PhotoModel) {
        queue.async { [weak self] in
            guard let self else { return }

            var currentPhotos = photos.value
            currentPhotos[index] = photo
            photos.send(currentPhotos)
        }
    }

    private func cacheImages(photoModels: [PhotoModel]) async throws -> [PhotoModel] {
        var retVal: [PhotoModel] = []
        try await withThrowingTaskGroup(of: PhotoModel?.self) { [weak self] group in
            guard let self else { return }

            photoModels.forEach { photoModel in
                guard let urls = photoModel.urls,
                      let url = URL(string: urls.thumb) else { return }

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
}
