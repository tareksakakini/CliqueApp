//
//  EventImageCache.swift
//  CliqueApp
//
//  Provides an in-memory cache for event images so we don’t repeatedly hit
//  the network when switching tabs or reopening screens.
//

import Foundation
import UIKit

final class EventImageCache {
    static let shared = EventImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private var inFlightTasks: [String: Task<UIImage?, Never>] = [:]
    private let lock = NSLock()
    
    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 50 * 1024 * 1024 // ~50 MB
    }
    
    func cachedImage(for url: String) -> UIImage? {
        cache.object(forKey: url as NSString)
    }
    
    @discardableResult
    func loadImage(from urlString: String, forceRefresh: Bool = false) async -> UIImage? {
        guard !urlString.isEmpty else { return nil }
        
        if !forceRefresh, let cached = cachedImage(for: urlString) {
            return cached
        }
        
        lock.lock()
        if let existingTask = inFlightTasks[urlString] {
            lock.unlock()
            return await existingTask.value
        }
        
        let downloadTask = Task<UIImage?, Never> { [weak self] in
            guard let self else { return nil }
            defer { self.finishTask(for: urlString) }
            
            guard let url = URL(string: urlString) else { return nil }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else { return nil }
                self.cache.setObject(image, forKey: urlString as NSString, cost: data.count)
                return image
            } catch {
                print("Failed to download event image (\(urlString)): \(error.localizedDescription)")
                return nil
            }
        }
        
        inFlightTasks[urlString] = downloadTask
        lock.unlock()
        
        return await downloadTask.value
    }
    
    func removeImage(for url: String) {
        cache.removeObject(forKey: url as NSString)
    }
    
    func clear() {
        cache.removeAllObjects()
    }
    
    private func finishTask(for url: String) {
        lock.lock()
        inFlightTasks[url] = nil
        lock.unlock()
    }
}
