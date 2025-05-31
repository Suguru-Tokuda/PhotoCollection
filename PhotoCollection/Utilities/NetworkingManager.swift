//
//  NetworkingManager.swift
//  PhotoCollection
//
//  Created by Suguru Tokuda on 5/19/25.
//

import Foundation
import Network

protocol Networking {
    func getData<T: Decodable>(url: URL, type: T.Type, queryItems: [URLQueryItem]) async throws -> T
}

enum NetworkError: Error {
    case badResponse
    case dataParsingError
    case invalidURL
    case noData
    case serverError
    case unknown
}

enum HeaderKeys: String {
    case authorization = "Authorization"
}

typealias Headers = [HeaderKeys: String]
struct PhotoResponse: Decodable {
    let page: Int
    let per_page: Int
    let photos: [Photo]
    // other fields as needed
    
    struct Photo: Decodable {
        let id: Int
        let photographer: String
        let src: Src
        
        struct Src: Decodable {
            let original: String
            let medium: String
            // add other sizes if needed
        }
    }
}

class NetworkingManager: Networking {
    func getData<T: Decodable>(url: URL, type: T.Type, queryItems: [URLQueryItem]) async throws -> T {
        do {
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            urlComponents?.queryItems = queryItems

            guard let url = urlComponents?.url else {
                throw NetworkError.invalidURL
            }

            let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
            return try handleResponse(data: data, response: response, type: type.self)
        } catch let error as URLError {
            throw error
        } catch let error as NetworkError {
            throw error
        } catch {
            throw error
        }
    }

    private func handleResponse<T: Decodable>(data: Data, response: URLResponse, type: T.Type) throws -> T {
        guard !data.isEmpty else { throw NetworkError.noData }

        if let res = response as? HTTPURLResponse,
           200..<300 ~= res.statusCode {
            do {
                return try JSONDecoder().decode(type.self, from: data)
            } catch {
                print(error)
                throw NetworkError.dataParsingError
            }
        } else {
            throw NetworkError.badResponse
        }
    }
}
