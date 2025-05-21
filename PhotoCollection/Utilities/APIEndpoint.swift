//
//  APIEndpoint.swift
//  SwiftConcurrencyDemo
//
//  Created by Suguru Tokuda on 5/19/25.
//

import Foundation

enum APIEndpoint {
    static let baseURL = "https://api.unsplash.com"

    case search

    var url: URL? {
        switch self {
        case .search:
            return URL(string: "\(Self.baseURL)/search/photos")
        }
    }
}
