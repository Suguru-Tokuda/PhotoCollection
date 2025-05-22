//
//  CacheTaskStore.swift
//  PhotoCollection
//
//  Created by Suguru Tokuda on 5/22/25.
//

import Foundation

protocol CacheTaskStoreProtocol {
    func add(task: Task<(), Never>, for id: String) async
    func remove(for id: String) async
    func task(for id: String) async -> Task<(), Never>?
    func removeAll() async
}

actor CacheTaskStore: CacheTaskStoreProtocol {
    private var tasks: [String: Task<(), Never>] = [:]

    func add(task: Task<(), Never>, for id: String) {
        tasks[id] = task
    }

    func remove(for id: String) {
        tasks[id]?.cancel()
        tasks[id] = nil
    }

    func task(for id: String) -> Task<(), Never>? {
        return tasks[id]
    }

    func removeAll() {
        tasks.forEach { $0.value.cancel() }
        tasks.removeAll()
    }
}
