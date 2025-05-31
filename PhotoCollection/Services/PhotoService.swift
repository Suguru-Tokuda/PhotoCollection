//
//  PhotoService.swift
//  PhotoCollection
//
//  Created by Suguru Tokuda on 5/19/25.
//

import Foundation

protocol PhotoServiceProtocol {
    func fetchPhotos(query: String, pageNumber: Int, perPage: Int) async throws -> PhotosResponseModel?
}

enum FlickrMethods: String {
    case search = "flickr.photos.search"
}

struct URLQueryParamKeys {
    static let tags = "tags"
    static let page = "page"
    static let perPage = "per_page"
    static let apiKey = "api_key"
    static let format = "format"
    static let noJsonCallback = "nojsoncallback"
    static let method = "method"
}

class PhotoSerice: PhotoServiceProtocol {
    struct Constants {
        static let json = "json"
    }

    private let baseURL = APIEndpoint.search.url
    private var imageBaseURL = APIEndpoint.imageURL.url
    private let networkingManager: Networking
    private var apiKey: String?
    

    init(networkingManager: Networking = NetworkingManager(), apiKeyManager: APIKeyManaging = APIKeyManager()) {
        self.networkingManager = networkingManager
        apiKey = apiKeyManager.getAPIKey()
    }

    func fetchPhotos(query: String, pageNumber: Int, perPage: Int = 21) async throws -> PhotosResponseModel? {
        guard let baseURL,
              let imageBaseURL,
              let apiKey = apiKey else { return nil }
        
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: URLQueryParamKeys.tags, value: query),
            URLQueryItem(name: URLQueryParamKeys.page, value: String(pageNumber)),
            URLQueryItem(name: URLQueryParamKeys.perPage, value: String(perPage)),
            URLQueryItem(name: URLQueryParamKeys.format, value: Constants.json),
            URLQueryItem(name: URLQueryParamKeys.noJsonCallback, value: String(1)),
            URLQueryItem(name: URLQueryParamKeys.method, value: FlickrMethods.search.rawValue),
            URLQueryItem(name: URLQueryParamKeys.apiKey, value: apiKey)
        ]

        let wrapperModel = try await networkingManager.getData(url: baseURL,
                                                         type: PhotosResponseWrapperModel.self,
                                                         queryItems: queryItems)
        var retVal = wrapperModel.photos
        retVal.constructImageURLs(baseURL: imageBaseURL.absoluteString)

        return retVal
    }
}
