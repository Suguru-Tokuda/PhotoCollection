//
//  PhotoModel.swift
//  PhotoCollection
//
//  Created by Suguru Tokuda on 5/17/25.
//

import Foundation

struct PhotosResponseWrapperModel: Decodable {
    let photos: PhotosResponseModel
    let stat: String
}

enum PhotoSize: String {
    case thumbnailS = "s" // 75px cropped square
    case thumbnailM = "q" // 150px cropped squre
    case thumbnailL = "t" // 100px
    case smallS = "m" // 240px
    case smallM = "n" // 320px
    case smallL = "w" // 400px
    case `default` = "" // 500px
    case mediumM = "z" // 640px
    case mediumL = "c" // 800px
    case largeS = "b" // 1024px
}

struct PhotosResponseModel: Decodable {
    let page: Int
    let pages: Int
    let perPage: Int
    let total: Int
    var photos: [PhotoModel]

    enum CodingKeys: String, CodingKey {
        case page
        case pages
        case perPage = "perpage"
        case total
        case photos = "photo"
    }

    mutating func constructImageURLs(baseURL: String) {
        self.photos = photos.map {
            var photo = $0
            photo.setThumbnailURL(baseURL: baseURL)
            return photo
        }
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
    let owner: String?
    let secret: String?
    let server: String?
    let farm: Int?
    let title: String?
    var loadingStatus: LoadingStatus?
    var thumbnailImageURL: String?
    var cachedImageURL: URL?
    var isPlaceholder: Bool?

    init(id: String,
         owner: String? = nil,
         secret: String? = nil,
         server: String? = nil,
         farm: Int? = nil,
         title: String? = nil,
         loadingStatus: LoadingStatus? = nil,
         cachedImageURL: URL? = nil,
         isPlaceholder: Bool? = nil
    ) {
        self.id = id
        self.owner = owner
        self.secret = secret
        self.server = server
        self.farm = farm
        self.title = title
        self.loadingStatus = loadingStatus
        self.cachedImageURL = cachedImageURL
        self.isPlaceholder = isPlaceholder
    }

    enum CodingKeys: String, CodingKey {
        case id
        case owner
        case secret
        case server
        case farm
        case title
    }

    mutating func setThumbnailURL(baseURL: String) {
        guard let server,
              let secret else { return }

        thumbnailImageURL = "\(baseURL)/\(server)/\(id)_\(secret)_\(PhotoSize.thumbnailM.rawValue).jpg"
    }
}
