//
//  AIEventCreationView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 2/13/25.
//

import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let timestamp: Date
}

struct EventSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let address: String
    let description: String
    let startTime: Date
    let endTime: Date
    let imageURL: String?
}

struct AIEventCreationView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var openAIService = OpenAIService()
    @State private var messages: [ChatMessage] = []
    @State private var currentInput: String = ""
    @State private var isTyping: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuggestions: Bool = false
    @State private var parsedSuggestions: [EventSuggestion] = []
    @State private var messagesWithSuggestions: Set<UUID> = []
    
    let user: UserModel
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Welcome message
                            if messages.isEmpty {
                                welcomeMessage
                                    .id("welcome")
                            }
                            
                            ForEach(messages) { message in
                                ChatBubbleView(
                                    message: message,
                                    onSuggestionsPressed: {
                                        showSuggestions = true
                                    },
                                    messagesWithSuggestions: messagesWithSuggestions
                                )
                                .id(message.id)
                            }
                            
                            // Typing indicator
                            if isTyping {
                                typingIndicator
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .background(Color(.systemGroupedBackground))
                    .onChange(of: messages.count) { _ in
                        withAnimation {
                            if let lastMessage = messages.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isTyping) { _ in
                        if isTyping {
                            withAnimation {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Message Input
                messageInputView
            }
            .navigationTitle("Create with AI")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
        .onAppear {
            addWelcomeMessage()
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: $showSuggestions) {
            if !parsedSuggestions.isEmpty {
                AISuggestionsView(
                    user: user,
                    selectedTab: $selectedTab,
                    suggestions: parsedSuggestions
                )
            }
        }
    }
    
    private var welcomeMessage: some View {
        VStack(spacing: 16) {
            Text("🎯")
                .font(.system(size: 60))
            
            Text("Let's Plan Your Perfect Event!")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("I'll ask you a few quick questions about your preferences to create personalized event suggestions just for you.")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }
    
    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isTyping ? 1.0 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: isTyping
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray5))
            .cornerRadius(18)
            
            Spacer()
        }
    }
    
    private var messageInputView: some View {
        HStack(spacing: 12) {
            TextField("Type your message...", text: $currentInput, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .lineLimit(1...5)
            
            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : Color(.accent))
            }
            .disabled(currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 0.5)
                .offset(y: -0.25),
            alignment: .top
        )
    }
    
    private func addWelcomeMessage() {
        // Add a small delay to make it feel more natural
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let welcomeMessage = ChatMessage(
                text: "Hey! I'll help you plan the perfect event. Let's start simple - indoor or outdoor vibe? 🎯",
                isFromUser: false,
                timestamp: Date()
            )
            messages.append(welcomeMessage)
        }
    }
    
    private func sendMessage() {
        let trimmedInput = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(
            text: trimmedInput,
            isFromUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        // Clear input and show typing indicator
        currentInput = ""
        isTyping = true
        
        // Get AI response
        Task {
            do {
                let aiResponseText = try await openAIService.sendMessage(trimmedInput)
                
                await MainActor.run {
                    isTyping = false
                    
                    // Check if the response contains suggestions
                    if aiResponseText.contains("📍") && aiResponseText.contains("🕐") {
                        parsedSuggestions = parseEventSuggestions(from: aiResponseText)
                        print("Parsed \(parsedSuggestions.count) suggestions:")
                        for (index, suggestion) in parsedSuggestions.enumerated() {
                            print("  \(index + 1). \(suggestion.title) at \(suggestion.address)")
                        }
                        
                        // Replace the detailed response with a clean summary
                        let cleanResponseText = "Perfect! I've created \(parsedSuggestions.count) personalized event suggestions based on your preferences. Each suggestion includes all the details you need - location, timing, and activities tailored just for you! 🎉"
                        
                        let aiResponse = ChatMessage(
                            text: cleanResponseText,
                            isFromUser: false,
                            timestamp: Date()
                        )
                        messages.append(aiResponse)
                        messagesWithSuggestions.insert(aiResponse.id)
                    } else {
                        // Normal response without suggestions
                        let aiResponse = ChatMessage(
                            text: aiResponseText,
                            isFromUser: false,
                            timestamp: Date()
                        )
                        messages.append(aiResponse)
                    }
                }
            } catch {
                await MainActor.run {
                    isTyping = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                    
                    // Add fallback message
                    let fallbackResponse = ChatMessage(
                        text: "Sorry, I'm having trouble connecting right now. Please try again later! 🤖",
                        isFromUser: false,
                        timestamp: Date()
                    )
                    messages.append(fallbackResponse)
                }
            }
        }
    }
    
    private func parseEventSuggestions(from text: String) -> [EventSuggestion] {
        var suggestions: [EventSuggestion] = []
        
        // Split by lines and process each potential event
        let lines = text.components(separatedBy: .newlines)
        var currentEvent: [String: String] = [:]
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for event title (starts with ** and ends with **)
            if trimmedLine.hasPrefix("**") && trimmedLine.hasSuffix("**") && trimmedLine.count > 4 {
                // Save previous event if exists
                if !currentEvent.isEmpty {
                    if let suggestion = createEventSuggestion(from: currentEvent) {
                        suggestions.append(suggestion)
                    }
                    currentEvent = [:]
                }
                
                // Extract title
                let title = String(trimmedLine.dropFirst(2).dropLast(2))
                currentEvent["title"] = title
            }
            // Check for location (venue name - address)
            else if trimmedLine.contains("📍") && trimmedLine.contains("Location:") {
                let location = trimmedLine.replacingOccurrences(of: "📍 **Location:**", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Split location into venue name and address
                if location.contains(" - ") {
                    let parts = location.components(separatedBy: " - ")
                    let venueName = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let address = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    // Store in the format expected by the app: "Title||Address"
                    currentEvent["address"] = "\(venueName)||\(address)"
                } else {
                    // Fallback if format doesn't match expected pattern
                    currentEvent["address"] = location
                }
            }
            // Check for description
            else if trimmedLine.contains("📝") && trimmedLine.contains("Description:") {
                let description = trimmedLine.replacingOccurrences(of: "📝 **Description:**", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                currentEvent["description"] = description
            }
            // Check for start time
            else if trimmedLine.contains("🕐") && trimmedLine.contains("Start Time:") {
                let startTime = trimmedLine.replacingOccurrences(of: "🕐 **Start Time:**", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                currentEvent["startTime"] = startTime
            }
            // Check for end time
            else if trimmedLine.contains("🕕") && trimmedLine.contains("End Time:") {
                let endTime = trimmedLine.replacingOccurrences(of: "🕕 **End Time:**", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                currentEvent["endTime"] = endTime
            }
            // Check for Unsplash search query
            else if trimmedLine.contains("🔎") && trimmedLine.contains("Unsplash Search:") {
                let searchQuery = trimmedLine.replacingOccurrences(of: "🔎 **Unsplash Search:**", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                currentEvent["imageURL"] = searchQuery
            }
        }
        
        // Don't forget the last event
        if !currentEvent.isEmpty {
            if let suggestion = createEventSuggestion(from: currentEvent) {
                suggestions.append(suggestion)
            }
        }
        
        return suggestions
    }
    
    private func createEventSuggestion(from eventData: [String: String]) -> EventSuggestion? {
        guard let title = eventData["title"],
              let address = eventData["address"],
              let description = eventData["description"],
              let startTimeString = eventData["startTime"],
              let endTimeString = eventData["endTime"] else {
            print("❌ Missing required fields for suggestion")
            return nil
        }
        
        print("🔍 Parsing dates:")
        print("  Start: '\(startTimeString)'")
        print("  End: '\(endTimeString)'")
        
        // Try multiple date formats (with year first, then fallbacks)
        let formatters = [
            "EEEE, MMMM d, yyyy 'at' h:mm a",    // Saturday, March 15, 2025 at 2:00 PM (target format)
            "EEEE, MMMM d'th', yyyy 'at' h:mm a", // Saturday, March 15th, 2025 at 2:00 PM
            "MMMM d, yyyy 'at' h:mm a",          // March 15, 2025 at 2:00 PM
            "MMMM d'th', yyyy 'at' h:mm a",      // March 15th, 2025 at 2:00 PM
            "EEEE, MMMM d 'at' h:mm a",          // Saturday, March 15 at 2:00 PM (fallback)
            "EEEE, MMMM d'th' 'at' h:mm a",      // Saturday, March 15th at 2:00 PM (fallback)
            "MMMM d 'at' h:mm a",                // March 15 at 2:00 PM (fallback)
            "MMMM d'th' 'at' h:mm a",            // March 15th at 2:00 PM (fallback)
            "EEEE 'at' h:mm a",                  // Saturday at 2:00 PM
            "h:mm a",                            // 2:00 PM
            "EEEE, MMMM d, yyyy",                // Saturday, March 15, 2025 (date only)
            "MMMM d, yyyy",                      // March 15, 2025 (date only)
            "EEEE, MMMM d",                      // Saturday, March 15 (date only, fallback)
            "MMMM d",                            // March 15 (date only, fallback)
            "EEEE"                               // Saturday (day only)
        ]
        
        var startTime: Date?
        var endTime: Date?
        
        // Try to parse start time
        var startTimeFormat: String?
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let parsed = formatter.date(from: startTimeString) {
                startTime = parsed
                startTimeFormat = format
                print("✅ Start time parsed with format: \(format)")
                break
            }
        }
        
        // Try to parse end time
        var endTimeFormat: String?
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let parsed = formatter.date(from: endTimeString) {
                endTime = parsed
                endTimeFormat = format
                print("✅ End time parsed with format: \(format)")
                break
            }
        }
        
        // Smart fallback for date-only formats
        if let parsedStartTime = startTime, let format = startTimeFormat {
            if (format.contains("EEEE, MMMM d") || format.contains("MMMM d")) && !format.contains("h:mm") {
                // Date only - add default time based on time of day preferences
                let calendar = Calendar.current
                let defaultStartTime = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: parsedStartTime) ?? parsedStartTime
                startTime = defaultStartTime
                print("📅 Added default 2:00 PM to date-only start time")
            }
        }
        
        if let parsedEndTime = endTime, let format = endTimeFormat {
            if (format.contains("EEEE, MMMM d") || format.contains("MMMM d")) && !format.contains("h:mm") {
                // Date only - add default end time (2 hours after start)
                if let finalStartTime = startTime {
                    let calendar = Calendar.current
                    let defaultEndTime = calendar.date(byAdding: .hour, value: 2, to: finalStartTime) ?? parsedEndTime
                    endTime = defaultEndTime
                    print("📅 Added default end time (2 hours after start)")
                }
            }
        }
        
        // If parsing fails, use smart defaults
        if startTime == nil || endTime == nil {
            print("⚠️ Date parsing failed, using defaults")
            let defaultStart = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            let defaultEnd = Calendar.current.date(byAdding: .hour, value: 2, to: defaultStart) ?? Date()
            
            startTime = startTime ?? defaultStart
            endTime = endTime ?? defaultEnd
        }
        
        let suggestion = EventSuggestion(
            title: title,
            address: address,
            description: description,
            startTime: startTime!,
            endTime: endTime!,
            imageURL: eventData["imageURL"]
        )
        
        print("📅 Final suggestion times:")
        print("  Start: \(startTime!)")
        print("  End: \(endTime!)")
        
        return suggestion
    }
}

struct ChatBubbleView: View {
    let message: ChatMessage
    let onSuggestionsPressed: (() -> Void)?
    let messagesWithSuggestions: Set<UUID>
    
    init(message: ChatMessage, onSuggestionsPressed: (() -> Void)? = nil, messagesWithSuggestions: Set<UUID> = []) {
        self.message = message
        self.onSuggestionsPressed = onSuggestionsPressed
        self.messagesWithSuggestions = messagesWithSuggestions
    }
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                userBubble
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    aiBubble
                    
                    // Show suggestions button if this message has suggestions
                    if !message.isFromUser && messagesWithSuggestions.contains(message.id) {
                        suggestionsButton
                    }
                }
                Spacer()
            }
        }
    }
    
    private var userBubble: some View {
        Text(message.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.accent))
            .foregroundColor(.white)
            .cornerRadius(18)
            .font(.system(size: 16))
    }
    
    private var aiBubble: some View {
        Text(message.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray5))
            .foregroundColor(.primary)
            .cornerRadius(18)
            .font(.system(size: 16))
    }
    
    private var suggestionsButton: some View {
        Button {
            onSuggestionsPressed?()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text("View Suggestions")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.orange,
                        Color.red
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var selectedTab = 0
        
        var body: some View {
            let mockUser = {
                var user = UserModel()
                user.uid = "preview-user"
                user.fullname = "John Doe"
                user.email = "john.doe@example.com"
                user.phoneNumber = "+1234567890"
                return user
            }()
            
            AIEventCreationView(
                user: mockUser,
                selectedTab: $selectedTab
            )
        }
    }
    
    return PreviewWrapper()
} 