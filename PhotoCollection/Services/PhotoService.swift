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

struct URLQueryParamKeys {
    static let query = "query"
    static let page = "page"
    static let perPage = "per_page"
    static let clientId = "client_id"
}

class PhotoSerice: PhotoServiceProtocol {
    private let baseURL = APIEndpoint.search.url
    private let networkingManager: Networking
    private var apiKey: String?

    init(networkingManager: Networking = NetworkingManager(), apiKeyManager: APIKeyManaging = APIKeyManager()) {
        self.networkingManager = networkingManager
        apiKey = apiKeyManager.getAPIKey()
    }

    func fetchPhotos(query: String, pageNumber: Int, perPage: Int = 21) async throws -> PhotosResponseModel? {
        guard let baseURL,
              let apiKey = apiKey else { return nil }
        
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: URLQueryParamKeys.query, value: query),
            URLQueryItem(name: URLQueryParamKeys.page, value: String(pageNumber)),
            URLQueryItem(name: URLQueryParamKeys.perPage, value: String(perPage)),
            URLQueryItem(name: URLQueryParamKeys.clientId, value: apiKey)
        ]

        return try await networkingManager.getData(url: baseURL,
                                                   type: PhotosResponseModel.self,
                                                   queryItems: queryItems)
    }
}
