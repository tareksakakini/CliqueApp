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
                                ChatBubbleView(message: message) {
                                    showSuggestions = true
                                }
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
            Text("🤖")
                .font(.system(size: 60))
            
            Text("Hello! I'm your AI event assistant.")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("Tell me about the event you'd like to create and I'll help you plan it!")
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
                text: "Hello! I'm your AI event assistant. Tell me about the event you'd like to create and I'll help you plan it! 🎉",
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
                    let aiResponse = ChatMessage(
                        text: aiResponseText,
                        isFromUser: false,
                        timestamp: Date()
                    )
                    messages.append(aiResponse)
                    
                    // Check if the response contains suggestions
                    if aiResponseText.contains("📍") && aiResponseText.contains("🕐") {
                        parsedSuggestions = parseEventSuggestions(from: aiResponseText)
                        print("Parsed \(parsedSuggestions.count) suggestions:")
                        for (index, suggestion) in parsedSuggestions.enumerated() {
                            print("  \(index + 1). \(suggestion.title) at \(suggestion.address)")
                        }
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
            // Check for address
            else if trimmedLine.contains("📍") && trimmedLine.contains("Address:") {
                let address = trimmedLine.replacingOccurrences(of: "📍 **Address:**", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                currentEvent["address"] = address
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
            return nil
        }
        
        // Parse dates (simplified - you might want to use a more sophisticated date parser)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d'th' 'at' h:mm a"
        
        // Try alternative formats if first one fails
        let alternativeFormatter = DateFormatter()
        alternativeFormatter.dateFormat = "EEEE, MMMM d 'at' h:mm a"
        
        guard let startTime = formatter.date(from: startTimeString) ?? alternativeFormatter.date(from: startTimeString),
              let endTime = formatter.date(from: endTimeString) ?? alternativeFormatter.date(from: endTimeString) else {
            // If parsing fails, use default times
            let defaultStart = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            let defaultEnd = Calendar.current.date(byAdding: .hour, value: 2, to: defaultStart) ?? Date()
            
            return EventSuggestion(
                title: title,
                address: address,
                description: description,
                startTime: defaultStart,
                endTime: defaultEnd
            )
        }
        
        return EventSuggestion(
            title: title,
            address: address,
            description: description,
            startTime: startTime,
            endTime: endTime
        )
    }
}

struct ChatBubbleView: View {
    let message: ChatMessage
    let onSuggestionsPressed: (() -> Void)?
    
    init(message: ChatMessage, onSuggestionsPressed: (() -> Void)? = nil) {
        self.message = message
        self.onSuggestionsPressed = onSuggestionsPressed
    }
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                userBubble
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    aiBubble
                    
                    // Show suggestions button if message contains structured data
                    if !message.isFromUser && (message.text.contains("📍") && message.text.contains("🕐")) {
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