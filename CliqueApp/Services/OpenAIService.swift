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
        You are a helpful AI assistant that specializes in helping users plan events. You are integrated into a mobile app called Yalla where users can create events and invite friends.

        **CURRENT DATE & TIME:** \(currentDateTime)

        Your goal is to understand their event preferences by gathering relevant information. Examples of relevant information is possible dates they're aiming for, times of the day that they are aiming for, location they are aiming for with varying levels of ambiguity, and possibly type of activities they are interested in for this event. Users can vary along a spectrum from knowing exactly what they want to having very little preference and keeping it very open for you to dictate the details.
        
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
        For each suggestion, provide these exact details in this format. Do not include brackets in your output:

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
