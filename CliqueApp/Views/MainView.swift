//
//  TabView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/27/25.
//

import SwiftUI

struct MainView: View {
    
    @EnvironmentObject private var vm: ViewModel
    @EnvironmentObject private var router: NotificationRouter
    
    @State var user: UserModel
    @State var selectedTab = 0
    @State private var deepLinkEvent: DeepLinkEvent?
    @State private var friendsSectionSelection: MyFriendsView.FriendSection = .friends
    
    private var pendingInvitesCount: Int {
        let identifiers = Set(user.identifierCandidates)
        let canonicalPhone = PhoneNumberFormatter.canonical(user.phoneNumber)
        guard !identifiers.isEmpty || !canonicalPhone.isEmpty else { return 0 }
        let now = Date()
        return vm.events.filter { event in
            let invitedById = event.attendeesInvited.contains { identifiers.contains($0) }
            let invitedByPhone = !canonicalPhone.isEmpty && event.invitedPhoneNumbers.contains(canonicalPhone)
            return (invitedById || invitedByPhone) && event.startDateTime >= now
        }.count
    }
    
    private var pendingFriendRequestsCount: Int {
        return vm.friendInviteReceived.count
    }
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                MyEventsView(user: user, isInviteView: false, selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "shareplay")
                        Text("My Events")
                    }
                    .tag(0)
                
                MyEventsView(user: user, isInviteView: true, selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "envelope.fill")
                        Text("Invites")
                    }
                    .badge(pendingInvitesCount > 0 ? "\(pendingInvitesCount)" : nil)
                    .tag(1)
                
                CreateEventView(user: user, selectedTab: $selectedTab, event: EventModel(), isNewEvent: true)
                    .tabItem {
                        Image(systemName: "plus.square.fill")
                        Text("New Event")
                    }
                    .tag(2)
                
                MyFriendsView(user: user, selectedSection: $friendsSectionSelection)
                    .tabItem {
                        Image(systemName: "person.2.fill")
                        Text("Friends")
                    }
                    .badge(pendingFriendRequestsCount > 0 ? "\(pendingFriendRequestsCount)" : nil)
                    .tag(3)
                
                MySettingsView(user: user)
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .tag(4)
                
            }
        }
        .navigationBarHidden(true)
        .task {
            print("📱 MainView .task starting for user id: \(user.uid)")
            
            guard !user.uid.isEmpty else {
                print("❌ CRITICAL ERROR: User has empty identifier in MainView!")
                return
            }
            
            await vm.refreshData(userId: user.uid)
            
            print("📱 MainView loaded for user: \(user.uid)")
            
            // CRITICAL: Ensure OneSignal is properly configured for this user
            print("🔍 Checking OneSignal configuration...")
            if !isOneSignalConfiguredForUser(expectedUserID: user.uid) {
                print("❌ OneSignal not properly configured, fixing...")
                // Clear any wrong association first
                await clearOneSignalForUser()
                await setupOneSignalForUser(userID: user.uid)
                
                // Verify it worked
                let verified = await verifyOneSignalState(expectedUserID: user.uid)
                if !verified {
                    print("⚠️ CRITICAL: OneSignal setup still failed in MainView!")
                }
            } else {
                print("✅ OneSignal correctly configured")
            }
            
            // Load profile pic (non-critical, silent failure is acceptable)
            do {
                try await vm.loadProfilePic(imageUrl: user.profilePic)
            } catch {
                print("Failed to load profile picture: \(error.localizedDescription)")
            }
        }
        .onAppear {
            // Change the background color of the TabBar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            if let pending = router.pendingRoute {
                handleRoute(pending)
            }
        }
        .onChange(of: router.pendingRoute) { _, newRoute in
            guard let destination = newRoute else { return }
            handleRoute(destination)
        }
        .tint(Color(.accent))
        .fullScreenCover(item: $deepLinkEvent, onDismiss: {
            deepLinkEvent = nil
        }) { deepLink in
            EventDetailView(event: deepLink.event,
                            user: user,
                            inviteView: deepLink.inviteView,
                            autoOpenChat: deepLink.openChat)
        }
    }
}

#Preview {
    MainView(user: UserData.userData[1])
        .environmentObject(ViewModel())
        .environmentObject(NotificationRouter.shared)
        .environmentObject(EventChatUnreadStore())
    
}

private extension MainView {
    func handleRoute(_ destination: NotificationRouter.Destination) {
        switch destination {
        case .eventDetail(let id, let inviteView, let preferredTab, let openChat):
            NotificationCenter.default.post(name: .dismissPresentedEventDetails, object: nil)
            Task {
                await presentEventRoute(eventId: id,
                                        inviteView: inviteView,
                                        preferredTab: preferredTab,
                                        openChat: openChat)
            }
        case .tab(let tab):
            selectedTab = tab.tabIndex
            router.consumeRoute()
        case .friends(let section):
            applyFriendSection(section)
            selectedTab = NotificationRouter.NotificationTab.friends.tabIndex
            router.consumeRoute()
        }
    }
    
    func applyFriendSection(_ shortcut: NotificationRouter.FriendSectionShortcut) {
        switch shortcut {
        case .friends:
            friendsSectionSelection = .friends
        case .requests:
            friendsSectionSelection = .requests
        case .sent:
            friendsSectionSelection = .sent
        }
    }
    
    func presentEventRoute(eventId: String,
                           inviteView: Bool,
                           preferredTab: NotificationRouter.NotificationTab?,
                           openChat: Bool) async {
        let targetTab = preferredTab ?? (inviteView ? .invites : .myEvents)
        await MainActor.run {
            selectedTab = targetTab.tabIndex
        }
        
        let refreshedEvent = await vm.refreshEventById(id: eventId)
        let fallbackEvent = vm.events.first(where: { $0.id == eventId })
        
        await MainActor.run {
            if let eventToDisplay = refreshedEvent ?? fallbackEvent {
                deepLinkEvent = DeepLinkEvent(event: eventToDisplay,
                                              inviteView: inviteView,
                                              openChat: openChat)
            } else {
                print("🔗 Unable to locate event with id \(eventId) for routing")
            }
            router.consumeRoute()
        }
    }
}

private struct DeepLinkEvent: Identifiable, Equatable {
    let id = UUID()
    let event: EventModel
    let inviteView: Bool
    let openChat: Bool
}
