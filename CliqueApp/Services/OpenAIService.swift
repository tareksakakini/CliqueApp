//
//  OpenAIService.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 2/13/25.
//

import Foundation

class OpenAIService: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private var conversationHistory: [[String: Any]] = []
    private let ticketmasterService = TicketmasterService()
    
    private func createSystemPrompt() -> String {
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm a zzz"
        let currentDateTime = formatter.string(from: currentDate)
        
        return """
        You are a helpful AI assistant that specializes in helping users plan events. You are integrated into a mobile app called Yalla where users can create events and invite friends.

        **CURRENT DATE & TIME:** \(currentDateTime)

        Your goal is to understand their event preferences by gathering relevant information. Examples of relevant information is possible dates they're aiming for, times of the day that they are aiming for, location they are aiming for with varying levels of ambiguity, and possibly type of activities they are interested in for this event. Users can vary along a spectrum from knowing exactly what they want to having very little preference and keeping it very open for you to dictate the details.
        
        **IMPORTANT**: You now have access to real-time event data from Ticketmaster! 

        **When to search Ticketmaster:**
        - User mentions specific artists, bands, or performers
        - User wants concerts, shows, sports games, theater, or any ticketed entertainment
        - User mentions a specific city or location
        - User wants to see "what's happening" or "events near me"
        - User asks for real events or actual shows
        
        **When to create general suggestions:**
        - User wants casual activities (coffee meetups, park visits, etc.)
        - User wants private gatherings or house parties
        - User mentions activities that typically don't require tickets
        - No location is specified and they want general ideas
        
        Always try Ticketmaster search first when appropriate, then supplement with your own suggestions if needed.
        
        During the course of the conversation, you should guage whether you feel like you have gathered enough information or not. If you have gathered enough information, you should move on to providing suggested plans. If not, you should think what is a good follow up question to gather the information you need. In other words, depending on the chat history, the kind of event they are going for, the information needed for such an event, and the information they already supplied, you can tell what else you need to know. If you feel like the user intentionally wants to keep it open, you should let them and not push for an answer or push for too detailed of info.
        
        Keep in mind that your suggestions are alternatives to each other. They are not parts of a full plan. Your scope is limited to a single plan and a single location per suggestion.

        **COMMUNICATION STYLE:**
        - **MATCH THE USER'S VIBE**: Mirror their communication style and energy level
        - **Short messages from user** → Keep responses brief, casual, and to the point
        - **Longer messages from user** → You can be more detailed and explanatory
        - **Enthusiastic user** → Match their energy with emojis and excitement
        - **Casual user** → Keep it chill and conversational

        **PROCESS:**
        - Ask about ONE preference category at a time, not multiple questions together
        - Keep each question simple and conversational
        - Once you have gathered what feels like enough information, transition to providing 5 to 10 specific event suggestions

        **WHEN PROVIDING SUGGESTIONS:**
        
        **For Real Ticketmaster Events:** When you find real events from Ticketmaster, present them exactly as they are returned from the function call, with all the real details including venue names, addresses, dates, times, and ticket links.
        
        **For General Event Ideas:** When creating your own event suggestions (not from Ticketmaster), provide these exact details in this format. Do not include brackets in your output:

        **[Event Title - MAXIMUM 4 WORDS, be concise and punchy]**
        📍 **Location:** [Venue/Business Name] - [Specific street address]
        📝 **Description:** [Brief description of the event/activity plus any helpful to know info]
        🕐 **Start Time:** [Day, Month Date, Year at Hour:Minute AM/PM - e.g., "Saturday, March 15, 2025 at 2:00 PM"]
        🕕 **End Time:** [Day, Month Date, Year at Hour:Minute AM/PM - e.g., "Saturday, March 15, 2025 at 4:00 PM"]
        🔎 **Unsplash Search:** [search terms for a photo that matches this event]

        **LOCATION FORMAT EXAMPLES:**
        📍 **Location:** Starbucks Coffee - 123 Main St, Los Angeles, CA 90210
        📍 **Location:** Central Park - 59th to 110th Street, Manhattan, NY 10022
        📍 **Location:** The Roosevelt Hotel - 45 E 45th St, New York, NY 10017
        📍 **Location:** Santa Monica Beach - 200 Santa Monica Pier, Santa Monica, CA 90401

        **IMPORTANT:** 
        - Ask only ONE question per response during the information gathering phase
        - When suggesting events, provide real, specific addresses and realistic future dates (not in the past)
        - Make sure start/end times align with their preferred time of day
        - Choose addresses in their specified geographic area
        - Try to offer a lot of suggestions so that the user can have more options to choose from. Provide as many as you can up to suggestions.
        
        Think before you answer. When generating your output start by the thinking component enclosed in <thinking> xml tags, and then once you feel you did all the thinking you needed to do, start coming up with your response and wrap it with <response> xml tags.
        """
    }
    
    init() {
        // Load API key from plist file
        if let path = Bundle.main.path(forResource: "OpenAI-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let apiKey = plist["OPENAI_API_KEY"] as? String {
            self.apiKey = apiKey
        } else {
            // Fallback - you can also set it directly here for testing
            self.apiKey = "YOUR_OPENAI_API_KEY_HERE"
            print("Warning: OpenAI API key not found in plist file")
        }
        
        // Initialize conversation with system prompt
        conversationHistory = [
            [
                "role": "system",
                "content": createSystemPrompt()
            ]
        ]
    }
    
    func sendMessage(_ message: String) async throws -> String {
        guard !apiKey.isEmpty && apiKey != "YOUR_OPENAI_API_KEY_HERE" else {
            throw OpenAIError.missingAPIKey
        }
        
        print("🤖 [OpenAI] User message: \(message)")
        
        // Add user message to conversation history
        conversationHistory.append([
            "role": "user",
            "content": message
        ])
        
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": conversationHistory,
            "max_tokens": 1000,
            "temperature": 0.7,
            "tools": getToolDefinitions()
        ]
        
        print("🤖 [OpenAI] Sending request with \(conversationHistory.count) messages and \(getToolDefinitions().count) tools")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OpenAIError.apiError(httpResponse.statusCode)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let aiMessage = firstChoice["message"] as? [String: Any] else {
            throw OpenAIError.invalidResponse
        }
        
        // Check if AI wants to call a function
        if let toolCalls = aiMessage["tool_calls"] as? [[String: Any]], !toolCalls.isEmpty {
            print("🔧 [OpenAI] AI wants to call \(toolCalls.count) function(s)")
            
            // Add AI's tool call message to history
            conversationHistory.append(aiMessage)
            
            // Execute the function calls
            for toolCall in toolCalls {
                let toolCallId = toolCall["id"] as? String ?? ""
                if let function = toolCall["function"] as? [String: Any],
                   let functionName = function["name"] as? String,
                   let argumentsString = function["arguments"] as? String {
                    
                    print("🔧 [OpenAI] Calling function: \(functionName) with args: \(argumentsString)")
                    
                    let functionResult = await executeFunction(name: functionName, arguments: argumentsString)
                    
                    print("🔧 [OpenAI] Function result: \(functionResult.prefix(200))...")
                    
                    // Add function result to conversation history
                    conversationHistory.append([
                        "role": "tool",
                        "tool_call_id": toolCallId,
                        "content": functionResult
                    ])
                }
            }
            
            // Make another API call to get the final response
            return try await sendFollowUpMessage()
        } else {
            // Regular text response
            guard let content = aiMessage["content"] as? String else {
                throw OpenAIError.invalidResponse
            }
            
            let aiResponse = content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("💬 [OpenAI] AI response (direct): \(aiResponse.prefix(200))...")
            
            // Add AI response to conversation history
            conversationHistory.append([
                "role": "assistant",
                "content": aiResponse
            ])
            
            return aiResponse
        }
    }
    
    private func sendFollowUpMessage() async throws -> String {
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": conversationHistory,
            "max_tokens": 1000,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OpenAIError.apiError(httpResponse.statusCode)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let aiMessage = firstChoice["message"] as? [String: Any],
              let content = aiMessage["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        let aiResponse = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("💬 [OpenAI] AI response (after function calls): \(aiResponse.prefix(200))...")
        
        // Add AI response to conversation history
        conversationHistory.append([
            "role": "assistant",
            "content": aiResponse
        ])
        
        return aiResponse
    }
    
    private func getToolDefinitions() -> [[String: Any]] {
        return [
            [
                "type": "function",
                "function": [
                    "name": "search_ticketmaster_events",
                    "description": "Search for real events from Ticketmaster based on user preferences like location, keyword, date range, and event type",
                    "parameters": [
                        "type": "object",
                        "properties": [
                            "keyword": [
                                "type": "string",
                                "description": "Keywords to search for (artist name, event name, etc.)"
                            ],
                            "city": [
                                "type": "string", 
                                "description": "City name to search in"
                            ],
                            "stateCode": [
                                "type": "string",
                                "description": "State code (e.g., 'CA', 'NY', 'TX')"
                            ],
                            "countryCode": [
                                "type": "string",
                                "description": "Country code (default 'US')"
                            ],
                            "startDateTime": [
                                "type": "string",
                                "description": "Start date in format YYYY-MM-DDTHH:MM:SSZ"
                            ],
                            "endDateTime": [
                                "type": "string", 
                                "description": "End date in format YYYY-MM-DDTHH:MM:SSZ"
                            ],
                            "classificationName": [
                                "type": "string",
                                "description": "Event category (music, sports, arts, family, etc.)"
                            ],
                            "size": [
                                "type": "integer",
                                "description": "Number of events to return (default 10, max 20)"
                            ]
                        ],
                        "required": []
                    ]
                ]
            ]
        ]
    }
    
    private func executeFunction(name: String, arguments: String) async -> String {
        switch name {
        case "search_ticketmaster_events":
            return await searchTicketmasterEvents(arguments: arguments)
        default:
            return "Unknown function: \(name)"
        }
    }
    
    private func searchTicketmasterEvents(arguments: String) async -> String {
        do {
            guard let argumentsData = arguments.data(using: .utf8),
                  let params = try JSONSerialization.jsonObject(with: argumentsData) as? [String: Any] else {
                return "Error: Could not parse function arguments"
            }
            
            let keyword = params["keyword"] as? String
            let city = params["city"] as? String
            let stateCode = params["stateCode"] as? String
            let countryCode = params["countryCode"] as? String ?? "US"
            let startDateTime = params["startDateTime"] as? String
            let endDateTime = params["endDateTime"] as? String
            let classificationName = params["classificationName"] as? String
            let size = params["size"] as? Int ?? 10
            
            let response = try await ticketmasterService.searchEvents(
                keyword: keyword,
                city: city,
                stateCode: stateCode,
                countryCode: countryCode,
                latitude: nil,
                longitude: nil,
                radius: "25",
                startDateTime: startDateTime,
                endDateTime: endDateTime,
                classificationName: classificationName,
                size: size
            )
            
            guard let events = response.embedded?.events, !events.isEmpty else {
                return "No events found matching the criteria."
            }
            
            // Format events for the AI
            var result = "Found \(events.count) events:\n\n"
            
            for (index, event) in events.enumerated() {
                result += "**Event \(index + 1): \(event.name)**\n"
                
                // Add venue information
                if let venue = event.embedded?.venues?.first {
                    result += "📍 Location: \(venue.name)"
                    if let address = venue.address?.line1 {
                        result += " - \(address)"
                    }
                    if let city = venue.city?.name, let state = venue.state?.name {
                        result += ", \(city), \(state)"
                    }
                    result += "\n"
                }
                
                // Add date/time information
                if let start = event.dates?.start {
                    if let localDate = start.localDate, let localTime = start.localTime {
                        result += "🕐 Date & Time: \(localDate) at \(localTime)\n"
                    } else if let localDate = start.localDate {
                        result += "🕐 Date: \(localDate)\n"
                    }
                }
                
                // Add price information
                if let priceRanges = event.priceRanges, !priceRanges.isEmpty {
                    let minPrice = priceRanges.compactMap { $0.min }.min()
                    let maxPrice = priceRanges.compactMap { $0.max }.max()
                    let currency = priceRanges.first?.currency ?? "USD"
                    
                    if let min = minPrice, let max = maxPrice {
                        result += "💰 Price Range: \(currency) \(min) - \(max)\n"
                    } else if let min = minPrice {
                        result += "💰 Starting Price: \(currency) \(min)\n"
                    }
                }
                
                // Add ticket URL
                if let ticketURL = event.url {
                    result += "🎫 Tickets: \(ticketURL)\n"
                }
                
                // Add event description if available
                if let description = event.info {
                    result += "📝 Description: \(description)\n"
                }
                
                // Add genre/category
                if let classification = event.classifications?.first {
                    var genres: [String] = []
                    if let segment = classification.segment?.name {
                        genres.append(segment)
                    }
                    if let genre = classification.genre?.name {
                        genres.append(genre)
                    }
                    if !genres.isEmpty {
                        result += "🎭 Category: \(genres.joined(separator: " - "))\n"
                    }
                }
                
                result += "\n"
            }
            
            print("📄 [OpenAI] Formatted Ticketmaster response (\(result.count) chars): \(result.prefix(300))...")
            
            return result
            
        } catch {
            print("❌ [OpenAI] Ticketmaster search error: \(error.localizedDescription)")
            return "Error searching events: \(error.localizedDescription)"
        }
    }
    
    func resetConversation() {
        conversationHistory = [
            [
                "role": "system",
                "content": createSystemPrompt()
            ]
        ]
    }
}

enum OpenAIError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(Int)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is missing. Please add your API key to the OpenAIService."
        case .invalidResponse:
            return "Invalid response from OpenAI API."
        case .apiError(let statusCode):
            return "OpenAI API error with status code: \(statusCode)"
        }
    }
} 
