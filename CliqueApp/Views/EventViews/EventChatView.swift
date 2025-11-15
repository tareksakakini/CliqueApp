//
//  EventChatView.swift
//  CliqueApp
//
//  Created by Codex on 3/7/25.
//

import SwiftUI

struct EventChatView: View {
    @ObservedObject var viewModel: EventChatViewModel
    @EnvironmentObject private var vm: ViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isComposerFocused: Bool
    
    private enum ScrollTarget: Hashable {
        case bottom
    }
    
    private let bottomSpacerHeight: CGFloat = 18
    
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        formatter.timeZone = TimeZone.autoupdatingCurrent
        return formatter
    }()
    
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
            EventChatActivityTracker.shared.enterChat(eventId: viewModel.event.id)
            viewModel.startMessagesListener()
            viewModel.markChatAsRead()
        }
        .onDisappear {
            EventChatActivityTracker.shared.leaveChat(eventId: viewModel.event.id)
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
            
            Text(viewModel.eventTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
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
                LazyVStack(spacing: 0) {
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
                        ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                            let shouldGroup = shouldGroupWithPreviousMessage(at: index)
                            
                            if shouldShowDayDivider(at: index) {
                                ChatDayDivider(label: dayLabel(for: message.createdAt))
                                    .padding(.top, index == 0 ? 12 : 20)
                                    .padding(.bottom, 8)
                            }
                            
                            EventChatBubble(message: message,
                                            isCurrentUser: viewModel.isCurrentUser(message),
                                            showsSenderName: !(shouldGroup && !viewModel.isCurrentUser(message)),
                                            viewModel: vm,
                                            hostIdentifier: viewModel.event.host)
                            .padding(.top, shouldGroup ? 4 : 12)
                            .id(message.id)
                        }
                    }
                    
                    Color.clear
                        .frame(height: bottomSpacerHeight)
                        .id(ScrollTarget.bottom)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .background(Color(.systemGroupedBackground))
            .onChange(of: viewModel.messages) { _, _ in
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(ScrollTarget.bottom, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(ScrollTarget.bottom, anchor: .bottom)
                }
            }
        }
    }
    
    private var composer: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Message", text: $viewModel.composerText, axis: .vertical)
                    .focused($isComposerFocused)
                    .lineLimit(1...4)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.black.opacity(0.05), lineWidth: 1)
                    )
                
                Button(action: {
                    // Dismiss keyboard first to clear any autocorrect suggestions
                    isComposerFocused = false
                    // Small delay to ensure autocorrect is dismissed before sending/clearing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.sendCurrentMessage()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(isComposerEmpty ? Color(.systemGray4) : Color(.accent))
                        )
                        .shadow(color: .black.opacity(isComposerEmpty ? 0 : 0.15), radius: 4, x: 0, y: 3)
                }
                .disabled(isComposerEmpty)
                .opacity(isComposerEmpty ? 0.6 : 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 4)
        }
        .background(
            Color(.systemBackground)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private var isComposerEmpty: Bool {
        trimmedComposerText.isEmpty
    }
    
    private var trimmedComposerText: String {
        viewModel.composerText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func shouldGroupWithPreviousMessage(at index: Int) -> Bool {
        guard index > 0 else { return false }
        let current = viewModel.messages[index]
        let previous = viewModel.messages[index - 1]
        let currentId = current.senderId.isEmpty ? current.senderHandle : current.senderId
        let previousId = previous.senderId.isEmpty ? previous.senderHandle : previous.senderId
        guard currentId == previousId else { return false }
        let calendar = Calendar.current
        guard calendar.isDate(current.createdAt, inSameDayAs: previous.createdAt) else { return false }
        return current.createdAt.timeIntervalSince(previous.createdAt) < 120
    }
    
    private func shouldShowDayDivider(at index: Int) -> Bool {
        guard !viewModel.messages.isEmpty else { return false }
        guard index > 0 else { return true }
        let calendar = Calendar.current
        let current = viewModel.messages[index].createdAt
        let previous = viewModel.messages[index - 1].createdAt
        return !calendar.isDate(current, inSameDayAs: previous)
    }
    
    private func dayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return Self.dayFormatter.string(from: date)
        }
    }
}

// MARK: - Day Divider

private struct ChatDayDivider: View {
    let label: String
    
    var body: some View {
        HStack(spacing: 12) {
            dividerLine
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
            dividerLine
        }
    }
    
    private var dividerLine: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.2))
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Chat Bubble

private struct EventChatBubble: View {
    let message: EventChatMessage
    let isCurrentUser: Bool
    let showsSenderName: Bool
    let viewModel: ViewModel
    let hostIdentifier: String
    
    init(message: EventChatMessage, isCurrentUser: Bool, showsSenderName: Bool = true, viewModel: ViewModel, hostIdentifier: String) {
        self.message = message
        self.isCurrentUser = isCurrentUser
        self.showsSenderName = showsSenderName
        self.viewModel = viewModel
        self.hostIdentifier = hostIdentifier
    }
    
    private var senderUser: UserModel? {
        viewModel.getUser(by: message.senderId.isEmpty ? message.senderHandle : message.senderId)
    }
    
    private var isHost: Bool {
        if !message.senderId.isEmpty {
            return message.senderId == hostIdentifier
        }
        return message.senderHandle == hostIdentifier
    }
    
    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
            if !isCurrentUser && showsSenderName {
                HStack(spacing: 6) {
                    if let senderUser = senderUser {
                        ProfilePictureView(user: senderUser, diameter: 20, isPhone: false)
                    }
                    HStack(spacing: 4) {
                        Text(message.senderName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        if isHost {
                            Text("(host)")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                    }
                }
                .padding(.leading, 8)
            }
            
            HStack(alignment: .bottom, spacing: 0) {
                if isCurrentUser { Spacer(minLength: 0) }
                HStack {
                    VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 6) {
                        Text(message.text)
                            .font(.system(size: 16))
                            .foregroundColor(isCurrentUser ? .white : .primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(message.createdAt, style: .time)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(isCurrentUser ? .white.opacity(0.7) : .secondary)
                    }
                }
                .padding(12)
                .background(isCurrentUser ? Color(.accent) : Color(.systemBackground))
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.6, alignment: isCurrentUser ? .trailing : .leading)
                if !isCurrentUser { Spacer(minLength: 0) }
            }
        }
        .transition(.move(edge: isCurrentUser ? .trailing : .leading).combined(with: .opacity))
    }
}

// MARK: - Chat Preview Row

struct EventChatPreviewRow: View {
    @ObservedObject var viewModel: EventChatViewModel
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    private var previewText: String {
        guard viewModel.summary.hasMessageHistory else {
            return "Be the first to say hello"
        }
        
        let senderIdentifier = viewModel.summary.lastMessageSenderId.isEmpty
            ? viewModel.summary.lastMessageSenderHandle
            : viewModel.summary.lastMessageSenderId
        let senderIsCurrentUser = !senderIdentifier.isEmpty &&
            senderIdentifier == viewModel.currentUser.stableIdentifier
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
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return Self.timeFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return Self.dateFormatter.string(from: date)
        }
    }
    
    private var unreadCount: Int {
        viewModel.unreadCountForCurrentUser
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
                Text("Event Chat")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(previewText)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 0) {
                Text(timestampText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .opacity(timestampText.isEmpty ? 0 : 1)
                
                Spacer(minLength: 0)
                
            Group {
                if unreadCount > 0 {
                    Text("\(unreadCount)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(.accent))
                        .clipShape(Capsule())
                } else {
                    Capsule()
                        .fill(Color.clear)
                        .frame(height: 24)
                }
            }
            .offset(y: -4)
        }
        .frame(height: 52)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
