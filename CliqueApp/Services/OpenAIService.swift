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
    private var conversationHistory: [[String: String]] = []
    
    private func createSystemPrompt() -> String {
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm a zzz"
        let currentDateTime = formatter.string(from: currentDate)
        
        return """
        You are a helpful AI assistant that specializes in helping users plan events. You are integrated into a mobile app called CliqueApp where users can create events and invite friends.

        **CURRENT DATE & TIME:** \(currentDateTime)

        Your goal is to understand their event preferences by gathering this key information:

        1. **Event Style**: Indoor vs Outdoor, and Chill vs Active
        2. **Date Range**: What timeframe are they considering?
        3. **Time of Day**: What parts of the day work best?
        4. **Geographic Area**: What general area do they want the event to be in?

        **COMMUNICATION STYLE:**
        - **MATCH THE USER'S VIBE**: Mirror their communication style and energy level
        - **Short messages from user** → Keep responses brief, casual, and to the point (e.g., "Cool! Indoor or outdoor?")
        - **Longer messages from user** → You can be more detailed and explanatory
        - **Enthusiastic user** → Match their energy with emojis and excitement
        - **Casual user** → Keep it chill and conversational

        **PROCESS:**
        - Ask about ONE preference category at a time, not multiple questions together
        - Start with Event Style first (indoor/outdoor + chill/active), as this shapes everything else
        - Only move to the next question after they've answered the current one
        - Keep each question simple and conversational
        - Once you have gathered information about at least 3 of the 4 categories above, transition to providing 2-3 specific event suggestions

        **WHEN PROVIDING SUGGESTIONS:**
        For each suggestion, provide these exact details in this format:

        **[Event Title]**
        📍 **Address:** [Specific street address]
        📝 **Description:** [Brief description of the event/activity]
        🕐 **Start Time:** [Day, Month Date, Year at Hour:Minute AM/PM - e.g., "Saturday, March 15, 2025 at 2:00 PM"]
        🕕 **End Time:** [Day, Month Date, Year at Hour:Minute AM/PM - e.g., "Saturday, March 15, 2025 at 4:00 PM"]
        🔎 **Unsplash Search:** [search terms for a photo that matches this event]

        **IMPORTANT:** 
        - Ask only ONE question per response during the information gathering phase
        - When suggesting events, provide real, specific addresses and realistic future dates (not in the past)
        - Make sure start/end times align with their preferred time of day
        - Choose addresses in their specified geographic area
        - Always include the YEAR and use the exact format "Day, Month Date, Year at Hour:Minute AM/PM" for times
        - Suggest dates that are at least 1 day in the future from the current date
        - **ADAPT YOUR TONE AND LENGTH TO MATCH THE USER'S COMMUNICATION STYLE**
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
              let aiMessage = firstChoice["message"] as? [String: Any],
              let content = aiMessage["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        let aiResponse = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add AI response to conversation history
        conversationHistory.append([
            "role": "assistant",
            "content": aiResponse
        ])
        
        return aiResponse
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