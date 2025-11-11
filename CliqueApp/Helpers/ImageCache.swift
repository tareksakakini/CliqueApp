//
//  ImageCache.swift
//  CliqueApp
//
//  Created for caching profile pictures
//

import Foundation
import UIKit

actor ImageCache {
    static let shared = ImageCache()
    
    private var cache: [String: UIImage] = [:]
    private var loadingTasks: [String: Task<UIImage?, Error>] = [:]
    
    private init() {}
    
    func getImage(for urlString: String) async -> UIImage? {
        // Return cached image if available
        if let cachedImage = cache[urlString] {
            return cachedImage
        }
        
        // If already loading, wait for that task
        if let existingTask = loadingTasks[urlString] {
            return try? await existingTask.value
        }
        
        // Create new loading task
        let task = Task<UIImage?, Error> {
            guard !urlString.isEmpty && urlString != "userDefault",
                  let url = URL(string: urlString) else {
                return nil
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    // Cache the image (no await needed since we're in the same actor)
                    self.cacheImage(image, for: urlString)
                    return image
                }
            } catch {
                print("Error loading image from \(urlString): \(error)")
            }
            
            return nil
        }
        
        loadingTasks[urlString] = task
        
        defer {
            loadingTasks.removeValue(forKey: urlString)
        }
        
        return try? await task.value
    }
    
    private func cacheImage(_ image: UIImage, for urlString: String) {
        cache[urlString] = image
    }
    
    func clearCache() {
        cache.removeAll()
        loadingTasks.removeAll()
    }
}

