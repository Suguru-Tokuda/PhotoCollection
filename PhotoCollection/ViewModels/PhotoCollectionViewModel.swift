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
    private var nextPageCursor: String?
    private var loadingStatus: LoadingStatus = .ready
    private var batchCaching: Bool
    private var batchTasks = Set<Task<Void, Never>>()

    private var queue = DispatchQueue(
        label: "com.PhotoCollection.PhotoCollectionViewModelQueueu",
        qos: .userInitiated
    )

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
              loadingStatus == .ready else { return }
        
        do {
            loadingStatus = .loading
            guard let photoResponseModel = try await photoService.fetchPhotos(query: query, pageNumber: pageNumber) else {
                return
            }
            handleResponse(response: photoResponseModel)
            loadingStatus = .ready
        } catch {
            errorPublisher.send(error)
        }
    }

    private func handleResponse(response: PhotosResponseModel) {
        guard !response.results.isEmpty else { return }

        if response.totalPages < (pageNumber + 1) {
            pageNumber += 1
        }

        var photos = self.photos.value

        for result in response.results {
            photoIndexMap[result.id] = photos.count
            photos.append(result)
        }

        self.photos.send(photos)

        // Do async image caching *after* updating map and sending value
        if batchCaching {
            Task(priority: .userInitiated) { [weak self] in
                guard let self else { return }
                do {
                    try await self.cacheImages(photoModels: response.results)
                } catch {
                    self.errorPublisher.send(error)
                }
            }
        } else {
            for photoModel in response.results {
                Task(priority: .userInitiated) { [weak self] in
                    await self?.cacheImage(photoModel: photoModel)
                }
            }
        }
    }

    private func cacheImage(photoModel: PhotoModel) async {
        guard let index = photoIndexMap[photoModel.id] else { return }

        var photoModel = photoModel
        guard let url = URL(string: photoModel.urls.small) else { return }

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

    private func cacheImages(photoModels: [PhotoModel]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { [weak self] group in
            guard let self else { return }

            for photoModel in photoModels {
                guard let url = URL(string: photoModel.urls.thumb) else { continue }

                group.addTask { [weak self] in
                    guard let self else { return }
                    
                    if let cachedImageURL = try await imageCachingManager.cacheImage(for: url) {
                        var photoModel = photoModel
                        photoModel.cachedImageURL = cachedImageURL
                        photoModel.loadingStatus = .loaded
                        guard let index = photoIndexMap[photoModel.id] else { return }

                        photos.value[index] = photoModel
                    }
                }
            }

            for try await _ in group {}
        }
    }
}
