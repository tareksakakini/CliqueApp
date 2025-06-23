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
    }
    
    func sendMessage(_ message: String) async throws -> String {
        guard !apiKey.isEmpty && apiKey != "YOUR_OPENAI_API_KEY_HERE" else {
            throw OpenAIError.missingAPIKey
        }
        
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let messages = [
            [
                "role": "system",
                "content": "You are a helpful AI assistant that specializes in helping users plan events. You are integrated into a mobile app called CliqueApp where users can create events and invite friends. Your goal is to understand their event preferences by gathering this key information:\n\n1. **Date Range**: What timeframe are they considering? (this weekend, next week, specific dates, flexible timing)\n2. **Time of Day**: What parts of the day work best? (morning, afternoon, evening, all day)\n3. **Geographic Area**: What general area or region do they want the event to be in? (neighborhood, city area, distance they're willing to travel)\n4. **Event Style**: Help them decide between:\n   - **Indoor vs Outdoor**: Do they prefer indoor venues or outdoor activities?\n   - **Chill vs Active**: Are they looking for relaxed/social activities or more energetic/physical ones?\n\n**PROCESS:**\n- Start by asking natural, conversational questions to understand their preferences\n- Once you have gathered enough information about at least 3 of the 4 categories above, transition to providing specific event suggestions\n- When providing suggestions, offer 2-3 concrete event ideas that match their preferences\n- Include suggested timing, general location types, and brief descriptions for each suggestion\n- Ask them which suggestion appeals to them most, or if they'd like different options\n\nBe friendly and help them explore possibilities. Don't ask for specific event titles, exact addresses, or detailed descriptions during the information gathering phase."
            ],
            [
                "role": "user",
                "content": message
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": messages,
            "max_tokens": 500,
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
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
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