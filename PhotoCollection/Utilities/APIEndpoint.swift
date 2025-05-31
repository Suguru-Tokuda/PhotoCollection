//
//  APIEndpoint.swift
//  SwiftConcurrencyDemo
//
//  Created by Suguru Tokuda on 5/19/25.
//

import Foundation

enum APIEndpoint {
    static let baseURL = "https://www.flickr.com"
    static let imageBaseURL = "https://live.staticflickr.com"

    case search
    case imageURL

    var url: URL? {
        switch self {
        case .search:
            return URL(string: "\(Self.baseURL)/services/rest?method=flickr.photos.search")
        case .imageURL:
            return URL(string: "\(Self.imageBaseURL)")
        }
    }
}
