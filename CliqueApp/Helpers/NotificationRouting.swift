//
//  NotificationRouting.swift
//  CliqueApp
//
//  Handles routing users to specific areas of the app when they interact
//  with push notifications.
//

import Foundation

/// Builds small JSON fragments that get embedded into the OneSignal payload.
enum NotificationRouteBuilder {
    private enum Screen: String {
        case eventDetail = "event_detail"
        case tab = "tab"
        case friends = "friend_requests"
    }
    
    /// Routes directly to an event detail screen.
    static func eventDetail(eventId: String,
                            inviteView: Bool,
                            preferredTab: NotificationRouter.NotificationTab?,
                            openChat: Bool = false) -> [String: Any] {
        var route: [String: Any] = [
            NotificationRouter.Key.screen: Screen.eventDetail.rawValue,
            NotificationRouter.Key.eventId: eventId,
            NotificationRouter.Key.inviteView: inviteView
        ]
        if let tab = preferredTab {
            route[NotificationRouter.Key.tab] = tab.rawValue
        }
        if openChat {
            route[NotificationRouter.Key.openChat] = openChat
        }
        return route
    }
    
    /// Routes to the friends tab and optionally pre-selects a section.
    static func friends(section: NotificationRouter.FriendSectionShortcut) -> [String: Any] {
        return [
            NotificationRouter.Key.screen: Screen.friends.rawValue,
            NotificationRouter.Key.section: section.rawValue,
            NotificationRouter.Key.tab: NotificationRouter.NotificationTab.friends.rawValue
        ]
    }
    
    /// Routes to a specific tab without deeper context.
    static func tab(_ tab: NotificationRouter.NotificationTab) -> [String: Any] {
        return [
            NotificationRouter.Key.screen: Screen.tab.rawValue,
            NotificationRouter.Key.tab: tab.rawValue
        ]
    }
}

/// Central place that stores pending notification routes until a SwiftUI view consumes them.
@MainActor
final class NotificationRouter: ObservableObject {
    
    enum Destination: Equatable {
        case eventDetail(id: String, inviteView: Bool, preferredTab: NotificationTab?, openChat: Bool)
        case tab(NotificationTab)
        case friends(section: FriendSectionShortcut)
    }
    
    enum NotificationTab: String, CaseIterable {
        case myEvents
        case invites
        case newEvent
        case friends
        case settings
        
        var tabIndex: Int {
            switch self {
            case .myEvents: return 0
            case .invites: return 1
            case .newEvent: return 2
            case .friends: return 3
            case .settings: return 4
            }
        }
    }
    
    enum FriendSectionShortcut: String {
        case friends
        case requests
        case sent
    }
    
    enum Key {
        static let screen = "screen"
        static let eventId = "eventId"
        static let inviteView = "inviteView"
        static let tab = "tab"
        static let section = "section"
        static let route = "route"
        static let openChat = "openChat"
    }
    
    private enum Screen: String {
        case eventDetail = "event_detail"
        case tab = "tab"
        case friends = "friend_requests"
    }
    
    static let shared = NotificationRouter()
    
    @Published var pendingRoute: Destination?
    
    private init() {}
    
    /// Stores the route payload so SwiftUI views can act on it later.
    func handleNotificationPayload(_ userInfo: [AnyHashable: Any]) {
        guard let destination = Self.extractDestination(from: userInfo) else {
            print("🔗 [Routing] No routing payload found in notification")
            return
        }
        
        pendingRoute = destination
        print("🔗 [Routing] Stored destination: \(destination)")
    }
    
    func consumeRoute() {
        pendingRoute = nil
    }
    
    private static func extractDestination(from userInfo: [AnyHashable: Any]) -> Destination? {
        guard let route = extractRouteDictionary(from: userInfo) else {
            return nil
        }
        
        guard let screen = route[Key.screen] as? String else { return nil }
        
        switch screen {
        case Screen.eventDetail.rawValue:
            guard let eventId = route[Key.eventId] as? String, !eventId.isEmpty else {
                return nil
            }
            let inviteView = (route[Key.inviteView] as? Bool) ?? (route[Key.inviteView] as? NSNumber)?.boolValue ?? false
            let preferredTab = (route[Key.tab] as? String).flatMap(NotificationTab.init(rawValue:))
            let openChat = (route[Key.openChat] as? Bool) ?? (route[Key.openChat] as? NSNumber)?.boolValue ?? false
            return .eventDetail(id: eventId, inviteView: inviteView, preferredTab: preferredTab, openChat: openChat)
            
        case Screen.friends.rawValue:
            let section = (route[Key.section] as? String).flatMap(FriendSectionShortcut.init(rawValue:)) ?? .requests
            return .friends(section: section)
            
        case Screen.tab.rawValue:
            guard let tabValue = route[Key.tab] as? String, let tab = NotificationTab(rawValue: tabValue) else {
                return nil
            }
            return .tab(tab)
            
        default:
            // Allow specifying tab directly via screen string.
            if let inferredTab = NotificationTab(rawValue: screen) {
                return .tab(inferredTab)
            }
            return nil
        }
    }
    
    private static func extractRouteDictionary(from userInfo: [AnyHashable: Any]) -> [String: Any]? {
        if let custom = userInfo["custom"] as? [String: Any],
           let additional = custom["a"] as? [String: Any],
           let route = additional[Key.route] as? [String: Any] {
            return route
        }
        
        if let direct = userInfo[Key.route] as? [String: Any] {
            return direct
        }
        
        if let additional = userInfo["data"] as? [String: Any],
           let route = additional[Key.route] as? [String: Any] {
            return route
        }
        
        return nil
    }
}

extension Notification.Name {
    static let dismissPresentedEventDetails = Notification.Name("DismissPresentedEventDetails")
}
