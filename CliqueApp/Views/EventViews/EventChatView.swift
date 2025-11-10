//
//  EventChatView.swift
//  CliqueApp
//
//  Created by Codex on 3/7/25.
//

import SwiftUI

struct EventChatView: View {
    @ObservedObject var viewModel: EventChatViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isComposerFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            messageList
            composer
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            viewModel.startMessagesListener()
            viewModel.markChatAsRead()
        }
        .onDisappear {
            viewModel.stopMessagesListener()
        }
        .onChange(of: viewModel.messages.count) { _, _ in
            viewModel.markChatAsRead()
        }
        .alert(viewModel.chatError?.title ?? "Error",
               isPresented: Binding(
                get: { viewModel.chatError != nil },
                set: { if !$0 { viewModel.chatError = nil } }
               )) {
            Button("OK", role: .cancel) { viewModel.chatError = nil }
        } message: {
            if let chatError = viewModel.chatError {
                Text(chatError.message)
            }
        }
    }
    
    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Back")
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Event Chat")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                Text(viewModel.eventTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.messages.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color(.accent))
                            Text("No messages yet")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Start the conversation for \(viewModel.eventTitle)")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 80)
                    } else {
                        ForEach(viewModel.messages) { message in
                            EventChatBubble(message: message,
                                            isCurrentUser: viewModel.isCurrentUser(message))
                            .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .background(Color(.systemGroupedBackground))
            .onChange(of: viewModel.messages) { _, messages in
                if let lastId = messages.last?.id {
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
            .onAppear {
                if let lastId = viewModel.messages.last?.id {
                    DispatchQueue.main.async {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var composer: some View {
        VStack(spacing: 8) {
            Divider()
            HStack(spacing: 12) {
                TextField("Message", text: $viewModel.composerText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($isComposerFocused)
                    .lineLimit(1...4)
                
                Button(action: {
                    viewModel.sendCurrentMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(viewModel.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color(.systemGray3) : Color(.accent))
                        .clipShape(Circle())
                }
                .disabled(viewModel.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Chat Bubble

private struct EventChatBubble: View {
    let message: EventChatMessage
    let isCurrentUser: Bool
    
    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
            if !isCurrentUser {
                Text(message.senderName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(isCurrentUser ? .trailing : .leading, 8)
            }
            
            HStack {
                if isCurrentUser { Spacer() }
                VStack(alignment: .leading, spacing: 6) {
                    Text(message.text)
                        .font(.system(size: 16))
                        .foregroundColor(isCurrentUser ? .white : .primary)
                    
                    Text(message.createdAt, style: .time)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isCurrentUser ? .white.opacity(0.7) : .secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(12)
                .background(isCurrentUser ? Color(.accent) : Color(.systemBackground))
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                if !isCurrentUser { Spacer() }
            }
        }
        .transition(.move(edge: isCurrentUser ? .trailing : .leading).combined(with: .opacity))
    }
}

// MARK: - Chat Preview Row

struct EventChatPreviewRow: View {
    @ObservedObject var viewModel: EventChatViewModel
    
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    private var previewText: String {
        guard viewModel.summary.hasMessageHistory else {
            return "Be the first to say hello"
        }
        
        let senderIsCurrentUser = viewModel.summary.lastMessageSenderEmail == viewModel.currentUser.email
        if senderIsCurrentUser {
            return "You: \(viewModel.summary.lastMessage)"
        } else if viewModel.summary.lastMessageSender.isEmpty {
            return viewModel.summary.lastMessage
        } else {
            return "\(viewModel.summary.lastMessageSender): \(viewModel.summary.lastMessage)"
        }
    }
    
    private var timestampText: String {
        guard let date = viewModel.summary.lastMessageAt else { return "" }
        return Self.timestampFormatter.string(from: date)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(.accent).opacity(0.15))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Color(.accent))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Event Chat")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if !timestampText.isEmpty {
                        Text(timestampText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(previewText)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            if viewModel.unreadCountForCurrentUser > 0 {
                Text("\(viewModel.unreadCountForCurrentUser)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color(.accent))
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
