//
//  TicketmasterService.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 2/13/25.
//

import Foundation

class TicketmasterService: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://app.ticketmaster.com/discovery/v2"
    
    init() {
        // Load API key from plist file
        if let path = Bundle.main.path(forResource: "Ticketmaster-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let apiKey = plist["TICKETMASTER_API_KEY"] as? String {
            self.apiKey = apiKey
        } else {
            // Fallback - you can also set it directly here for testing
            self.apiKey = "YOUR_TICKETMASTER_API_KEY_HERE"
            print("Warning: Ticketmaster API key not found in plist file")
        }
    }
    
    func searchEvents(keyword: String? = nil, 
                     city: String? = nil, 
                     stateCode: String? = nil, 
                     countryCode: String? = "US",
                     latitude: Double? = nil,
                     longitude: Double? = nil,
                     radius: String? = "25",
                     startDateTime: String? = nil,
                     endDateTime: String? = nil,
                     classificationName: String? = nil,
                     size: Int = 20) async throws -> TicketmasterEventResponse {
        
        print("🎫 [Ticketmaster] Searching events with params:")
        print("   keyword: \(keyword ?? "nil")")
        print("   city: \(city ?? "nil")")
        print("   stateCode: \(stateCode ?? "nil")")
        print("   classification: \(classificationName ?? "nil")")
        print("   size: \(size)")
        
        guard !apiKey.isEmpty && apiKey != "YOUR_TICKETMASTER_API_KEY_HERE" else {
            print("❌ [Ticketmaster] Missing API key")
            throw TicketmasterError.missingAPIKey
        }
        
        var urlComponents = URLComponents(string: "\(baseURL)/events.json")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "size", value: String(size))
        ]
        
        // Add optional parameters
        if let keyword = keyword {
            queryItems.append(URLQueryItem(name: "keyword", value: keyword))
        }
        if let city = city {
            queryItems.append(URLQueryItem(name: "city", value: city))
        }
        if let stateCode = stateCode {
            queryItems.append(URLQueryItem(name: "stateCode", value: stateCode))
        }
        if let countryCode = countryCode {
            queryItems.append(URLQueryItem(name: "countryCode", value: countryCode))
        }
        if let latitude = latitude, let longitude = longitude {
            queryItems.append(URLQueryItem(name: "latlong", value: "\(latitude),\(longitude)"))
        }
        if let radius = radius {
            queryItems.append(URLQueryItem(name: "radius", value: radius))
        }
        if let startDateTime = startDateTime {
            queryItems.append(URLQueryItem(name: "startDateTime", value: startDateTime))
        }
        if let endDateTime = endDateTime {
            queryItems.append(URLQueryItem(name: "endDateTime", value: endDateTime))
        }
        if let classificationName = classificationName {
            queryItems.append(URLQueryItem(name: "classificationName", value: classificationName))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            print("❌ [Ticketmaster] Invalid URL")
            throw TicketmasterError.invalidURL
        }
        
        print("🌐 [Ticketmaster] API URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TicketmasterError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ [Ticketmaster] API error: HTTP \(httpResponse.statusCode)")
            throw TicketmasterError.apiError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let eventResponse = try decoder.decode(TicketmasterEventResponse.self, from: data)
        
        let eventCount = eventResponse.embedded?.events?.count ?? 0
        print("✅ [Ticketmaster] Found \(eventCount) events")
        
        if eventCount > 0 {
            print("📋 [Ticketmaster] First few events:")
            eventResponse.embedded?.events?.prefix(3).forEach { event in
                print("   - \(event.name)")
            }
        }
        
        return eventResponse
    }
    
    func getEventDetails(eventId: String) async throws -> TicketmasterEvent {
        guard !apiKey.isEmpty && apiKey != "YOUR_TICKETMASTER_API_KEY_HERE" else {
            throw TicketmasterError.missingAPIKey
        }
        
        let urlString = "\(baseURL)/events/\(eventId).json?apikey=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw TicketmasterError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TicketmasterError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw TicketmasterError.apiError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let event = try decoder.decode(TicketmasterEvent.self, from: data)
        
        return event
    }
}

// MARK: - Data Models

struct TicketmasterEventResponse: Codable {
    let embedded: EmbeddedEvents?
    let page: PageInfo?
    
    private enum CodingKeys: String, CodingKey {
        case embedded = "_embedded"
        case page
    }
}

struct EmbeddedEvents: Codable {
    let events: [TicketmasterEvent]?
}

struct TicketmasterEvent: Codable {
    let id: String
    let name: String
    let url: String?
    let info: String?
    let pleaseNote: String?
    let images: [EventImage]?
    let dates: EventDates?
    let classifications: [Classification]?
    let priceRanges: [PriceRange]?
    let embedded: EmbeddedEventDetails?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, url, info, pleaseNote, images, dates, classifications, priceRanges
        case embedded = "_embedded"
    }
}

struct EventImage: Codable {
    let ratio: String?
    let url: String
    let width: Int?
    let height: Int?
    let fallback: Bool?
}

struct EventDates: Codable {
    let start: EventDate?
    let end: EventDate?
    let timezone: String?
    let status: EventStatus?
}

struct EventDate: Codable {
    let localDate: String?
    let localTime: String?
    let dateTime: String?
    let dateTBD: Bool?
    let dateTBA: Bool?
    let timeTBA: Bool?
    let noSpecificTime: Bool?
}

struct EventStatus: Codable {
    let code: String?
}

struct Classification: Codable {
    let primary: Bool?
    let segment: ClassificationDetail?
    let genre: ClassificationDetail?
    let subGenre: ClassificationDetail?
    let type: ClassificationDetail?
    let subType: ClassificationDetail?
    let family: Bool?
}

struct ClassificationDetail: Codable {
    let id: String?
    let name: String?
}

struct PriceRange: Codable {
    let type: String?
    let currency: String?
    let min: Double?
    let max: Double?
}

struct EmbeddedEventDetails: Codable {
    let venues: [Venue]?
    let attractions: [Attraction]?
}

struct Venue: Codable {
    let id: String?
    let name: String
    let type: String?
    let url: String?
    let locale: String?
    let timezone: String?
    let city: VenueCity?
    let state: VenueState?
    let country: VenueCountry?
    let address: VenueAddress?
    let location: VenueLocation?
    let postalCode: String?
    let images: [EventImage]?
}

struct VenueCity: Codable {
    let name: String
}

struct VenueState: Codable {
    let name: String
    let stateCode: String
}

struct VenueCountry: Codable {
    let name: String
    let countryCode: String
}

struct VenueAddress: Codable {
    let line1: String?
    let line2: String?
    let line3: String?
}

struct VenueLocation: Codable {
    let longitude: String?
    let latitude: String?
}

struct Attraction: Codable {
    let id: String?
    let name: String
    let type: String?
    let url: String?
    let locale: String?
    let images: [EventImage]?
    let classifications: [Classification]?
}

struct PageInfo: Codable {
    let size: Int?
    let totalElements: Int?
    let totalPages: Int?
    let number: Int?
}

// MARK: - Error Types

enum TicketmasterError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case apiError(Int)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Ticketmaster API key is missing. Please add your API key to the TicketmasterService."
        case .invalidURL:
            return "Invalid URL for Ticketmaster API request."
        case .invalidResponse:
            return "Invalid response from Ticketmaster API."
        case .apiError(let statusCode):
            return "Ticketmaster API error with status code: \(statusCode)"
        }
    }
}

// MARK: - Helper Extensions

extension TicketmasterEvent {
    var formattedEventInfo: String {
        var info = "**\(name)**\n"
        
        // Add venue information
        if let venue = embedded?.venues?.first {
            info += "📍 **Location:** \(venue.name)"
            if let address = venue.address?.line1 {
                info += " - \(address)"
            }
            if let city = venue.city?.name, let state = venue.state?.name {
                info += ", \(city), \(state)"
            }
            info += "\n"
        }
        
        // Add event description
        if let description = self.info {
            info += "📝 **Description:** \(description)\n"
        }
        
        // Add date/time information
        if let start = dates?.start {
            if let localDate = start.localDate, let localTime = start.localTime {
                info += "🕐 **Date & Time:** \(localDate) at \(localTime)\n"
            } else if let localDate = start.localDate {
                info += "🕐 **Date:** \(localDate)\n"
            }
        }
        
        // Add price information
        if let priceRanges = priceRanges, !priceRanges.isEmpty {
            let minPrice = priceRanges.compactMap { $0.min }.min()
            let maxPrice = priceRanges.compactMap { $0.max }.max()
            let currency = priceRanges.first?.currency ?? "USD"
            
            if let min = minPrice, let max = maxPrice {
                info += "💰 **Price Range:** \(currency) \(min) - \(max)\n"
            } else if let min = minPrice {
                info += "💰 **Starting Price:** \(currency) \(min)\n"
            }
        }
        
        // Add ticket URL
        if let ticketURL = url {
            info += "🎫 **Tickets:** [Buy Here](\(ticketURL))\n"
        }
        
        // Add genre/category
        if let classification = classifications?.first {
            var genres: [String] = []
            if let segment = classification.segment?.name {
                genres.append(segment)
            }
            if let genre = classification.genre?.name {
                genres.append(genre)
            }
            if !genres.isEmpty {
                info += "🎭 **Category:** \(genres.joined(separator: " - "))\n"
            }
        }
        
        // Add any important notes
        if let notes = pleaseNote {
            info += "📋 **Please Note:** \(notes)\n"
        }
        
        return info
    }
    
    var unsplashSearchTerms: String {
        var terms: [String] = []
        
        // Add event name words
        let whitespaceAndPunctuation = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        let eventWords = name.components(separatedBy: whitespaceAndPunctuation)
            .filter { !$0.isEmpty && $0.count > 2 }
        terms.append(contentsOf: eventWords.prefix(2))
        
        // Add genre information
        if let classification = classifications?.first {
            if let segment = classification.segment?.name {
                terms.append(segment.lowercased())
            }
            if let genre = classification.genre?.name {
                terms.append(genre.lowercased())
            }
        }
        
        // Add general event terms
        terms.append("concert")
        terms.append("event")
        
        return terms.prefix(4).joined(separator: " ")
    }
} 