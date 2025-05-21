//
//  APIKeyModel.swift
//  PhotoCollection
//
//  Created by Suguru Tokuda on 5/19/25.
//

import Foundation

struct APIKeyModel: Decodable {
    let apiKey: String

    enum CodingKeys: String, CodingKey {
        case apiKey = "UNSPLASH_API_KEY"
    }
}
