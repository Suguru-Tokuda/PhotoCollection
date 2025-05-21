//
//  ImageCachingManager.swift
//  PhotoCollection
//
//  Created by Suguru Tokuda on 5/19/25.
//

import CryptoKit
import UIKit

protocol ImageCachingManaging {
    func cacheImage(for url: URL) async throws -> URL?
    func getCachedImageURL(for url: URL) throws -> URL?
}

enum ImageCachingError: Error {
    case cacheDirectoryURLUnavailable
    case imageNotFound
    case imageCachingFailed
    case downloadImageFailed
}

final class ImageCachingManager: ImageCachingManaging {
    private var fileManager: FileManager
    private var cacheDirectoryURL: URL?

    init(fileManager: FileManager = FileManager.default) {
        self.fileManager = fileManager

        cacheDirectoryURL = self.fileManager
            .urls(for: .cachesDirectory,
                  in: .userDomainMask).first
    }

    func downloadImage(_ url: URL) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard !data.isEmpty else { throw NetworkError.noData }
            
            guard let res = response as? HTTPURLResponse,
                  200..<300 ~= res.statusCode else {
                throw NetworkError.badResponse
            }

            return data
        } catch {
            throw NetworkError.unknown
        }
    }

    @discardableResult
    func cacheImage(for url: URL) async throws -> URL? {
        guard let cacheDirectoryURL = cacheDirectoryURL else {
            throw ImageCachingError.cacheDirectoryURLUnavailable
        }

        if let cachedURL = try? getCachedImageURL(for: url) {
            return cachedURL
        }

        var data: Data
        
        do {
            data = try await downloadImage(url)
        } catch {
            throw ImageCachingError.downloadImageFailed
        }

        let fileName = cacheFileName(for: url)
        let fileURL = cacheDirectoryURL.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            try fileManager.setAttributes([.creationDate: Date()], ofItemAtPath: fileURL.path)
            return fileURL
        } catch {
            throw ImageCachingError.imageCachingFailed
        }
    }
    
    func getCachedImageURL(for url: URL) throws -> URL? {
        guard let cacheDirectoryURL = cacheDirectoryURL else {
            throw ImageCachingError.cacheDirectoryURLUnavailable
        }

        let fileName = cacheFileName(for: url)
        let fileURL = cacheDirectoryURL.appendingPathComponent(fileName)

        if !fileManager.fileExists(atPath: fileURL.path) {
            throw ImageCachingError.imageNotFound
        }

        return fileURL
    }

    func cacheFileName(for url: URL) -> String {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
