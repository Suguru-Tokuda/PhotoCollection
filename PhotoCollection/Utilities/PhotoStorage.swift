//
//  PhotoStorage.swift
//  PhotoCollection
//
//  Created by Suguru Tokuda on 5/22/25.
//

import Foundation

protocol PhotoStorageProtocol {
    func getPhotos() async -> [PhotoModel]
    func addPhotos(newPhotos: [PhotoModel]) async
    func updatePhoto(at index: Int, with photo: PhotoModel) async
    func setPhotos(_ newPhotos: [PhotoModel]) async
    func removePhotos(where shouldRemove: @Sendable (PhotoModel) -> Bool) async
    func getIndex(_ id: String) async -> Int?
}

actor PhotoStorage: PhotoStorageProtocol {
    private var photos: [PhotoModel] = []
    private var photoIds = Set<String>()
    private var indexMap = Dictionary<String, Int>()

    func getPhotos() -> [PhotoModel] {
        photos
    }

    func addPhotos(newPhotos: [PhotoModel]) {
        for photo in newPhotos {
            if let index = indexMap[photo.id] {
                updatePhoto(at: index, with: photo)
            } else {
                indexMap[photo.id] = photos.count
                photos.append(photo)
            }
        }
    }

    func updatePhoto(at index: Int, with photo: PhotoModel) {
        guard index <= photos.count else { return }

        photos[index] = photo
    }

    func setPhotos(_ newPhotos: [PhotoModel]) {
        photos = newPhotos
        photoIds = Set(photos.map( { $0.id }))
        indexMap.removeAll()
        photos.enumerated().forEach { (index, photo) in
            indexMap[photo.id] = index
        }
    }

    func removePhotos(where shouldRemove: @Sendable (PhotoModel) -> Bool) {
        let photosToRemove = photos.filter(shouldRemove)
        photosToRemove.forEach { indexMap[$0.id] = nil }
        photos.removeAll(where: shouldRemove)
    }

    func getIndex(_ id: String) -> Int? {
        indexMap[id]
    }
}
