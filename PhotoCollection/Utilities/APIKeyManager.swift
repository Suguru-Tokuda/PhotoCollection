//
//  APIKeyManager.swift
//  SwiftConcurrencyDemo
//
//  Created by Suguru Tokuda on 5/19/25.
//

import Foundation

protocol APIKeyManaging {
    func getAPIKey() -> String?
}

enum APIKeyError: Error {
    case resourceNotFound(URL?)
    case keyNotFound
    case parsingFailed
}

class APIKeyManager: APIKeyManaging {
    private struct Constants {
        let apiKeysFileName = "APIKeys"
        let plist = "plist"
    }

    func getAPIKey() -> String? {
        do {
            let apiKeyModel = try getData(resourse: Constants().apiKeysFileName, type: APIKeyModel.self)
            return apiKeyModel.apiKey
        } catch {
            return nil
        }
    }

    private func getData<T>(resourse: String, type: T.Type) throws -> T where T : Decodable {
        guard let url = Bundle.main.url(forResource: resourse, withExtension: Constants().plist) else {
            throw APIKeyError.resourceNotFound(nil)
        }

        var data: Data

        do {
            data = try Data(contentsOf: url)
        } catch {
            throw APIKeyError.resourceNotFound(url)
        }

        do {
            return try PropertyListDecoder().decode(type.self, from: data)
        } catch {
            throw APIKeyError.parsingFailed
        }
    }
}
