import Foundation

class UnsplashService {
    static let shared = UnsplashService()
    private let accessKey: String
    private let baseURL = "https://api.unsplash.com/search/photos"

    init() {
        // Load API key from plist file
        if let path = Bundle.main.path(forResource: "Unsplash-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let accessKey = plist["UNSPLASH_ACCESS_KEY"] as? String {
            self.accessKey = accessKey
        } else {
            self.accessKey = ""
            print("Warning: Unsplash access key not found in plist file")
        }
    }

    func fetchImageURL(for query: String) async -> String? {
        // Check network connection before attempting operation
        do {
            try ErrorHandler.shared.validateNetworkConnection()
        } catch {
            print("Network offline, cannot fetch Unsplash image")
            return nil
        }
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        let urlString = "\(baseURL)?query=\(encodedQuery)&client_id=\(accessKey)&per_page=1"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]],
               let first = results.first,
               let urls = first["urls"] as? [String: Any],
               let imageUrl = urls["regular"] as? String {
                return imageUrl
            }
        } catch {
            print("Unsplash fetch error: \(error)")
        }
        return nil
    }
} 