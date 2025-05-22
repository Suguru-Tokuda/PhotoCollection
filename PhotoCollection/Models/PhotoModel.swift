//
//  PhotoModel.swift
//  PhotoCollection
//
//  Created by Suguru Tokuda on 5/17/25.
//

import Foundation

struct PhotosResponseModel: Decodable {
    let total: Int
    let totalPages: Int
    let results: [PhotoModel]

    enum CodingKeys: String, CodingKey {
        case total
        case totalPages = "total_pages"
        case results
    }
}

struct PhotoModel: Hashable, Decodable {
    static func == (lhs: PhotoModel, rhs: PhotoModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.cachedImageURL == rhs.cachedImageURL &&
        lhs.loadingStatus == rhs.loadingStatus
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(cachedImageURL)
        hasher.combine(loadingStatus)
    }
    
    let id: String
    let createdAt: String?
    let updatedAt: String?
    let width: Int?
    let height: Int?
    let color: String?
    let description: String?
    let urls: URLs?
    var loadingStatus: LoadingStatus?
    var cachedImageURL: URL?
    var isPlaceholder: Bool?

    init(id: String,
         createdAt: String? = nil,
         updatedAt: String? = nil,
         width: Int? = nil,
         height: Int? = nil,
         color: String? = nil,
         description: String? = nil,
         urls: URLs? = nil,
         loadingStatus: LoadingStatus? = nil,
         cachedImageURL: URL? = nil,
         isPlaceholder: Bool? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.width = width
        self.height = height
        self.color = color
        self.description = description
        self.urls = urls
        self.loadingStatus = loadingStatus
        self.cachedImageURL = cachedImageURL
        self.isPlaceholder = isPlaceholder
    }

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case width
        case height
        case color
        case description
        case urls
    }
}

struct URLs: Hashable, Decodable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
    let smallS3: String

    enum CodingKeys: String, CodingKey {
        case raw
        case full
        case regular
        case small
        case thumb
        case smallS3 = "small_s3"
    }
}

