//
//  UserData.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/23/25.
//

import Foundation

struct UserData {
    
    private static let tarekId = "user-tarek"
    private static let aliId = "user-ali"
    private static let hassanId = "user-hassan"
    private static let mohamadId = "user-mohamad"
    private static let jadId = "user-jad"
    
    static var friendshipData: [String: [String]] = [
        tarekId: [aliId, hassanId, mohamadId],
        hassanId: [tarekId, jadId],
        jadId: [hassanId],
        mohamadId: [tarekId],
        aliId: [tarekId]
    ]
    
    static var friendInviteReceived: [String: [String]] = [
        tarekId: [jadId]
    ]
        
    static var userData: [UserModel] = [
        UserModel(
            uid: tarekId,
            authUID: "auth-\(tarekId)",
            fullname: "Tarek Sakakini",
            username: "tarek",
            createdAt: Date(),
            profilePic: "https://firebasestorage.googleapis.com:443/v0/b/cliqueapp-3834b.firebasestorage.app/o/profile_pictures%2FdWqRV0mlUWMCipVVAOp2NuADoBE3.jpg?alt=media&token=5be91c8f-2960-40a3-ae63-f511fc612a75"
        ),
        UserModel(
            uid: aliId,
            authUID: "auth-\(aliId)",
            fullname: "Ali Kanj",
            username: "ali",
            createdAt: Date()
        ),
        UserModel(
            uid: hassanId,
            authUID: "auth-\(hassanId)",
            fullname: "Hassan Dbouk",
            username: "hassan",
            createdAt: Date()
        ),
        UserModel(
            uid: mohamadId,
            authUID: "auth-\(mohamadId)",
            fullname: "Mohamad El Hajj",
            username: "mohamad",
            createdAt: Date()
        ),
        UserModel(
            uid: jadId,
            authUID: "auth-\(jadId)",
            fullname: "Jad Yaacoub",
            username: "jad",
            createdAt: Date()
        )
    ]
    
    static var eventData: [EventModel] = [
        EventModel(
            id: "1",
            title: "Snowboarding",
            location: "Northstar",
            startDateTime: Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 5, hour: 11, minute: 10))!,
            endDateTime: Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 5, hour: 11, minute: 10))!,
            attendeesAccepted: [tarekId, aliId],
            attendeesInvited: [jadId, hassanId],
            host: tarekId
        ),
        EventModel(
            id: "2",
            title: "Board Game Night",
            location: "George and Marias",
            startDateTime: Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 4, hour: 11, minute: 10))!,
            endDateTime: Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 4, hour: 11, minute: 10))!,
            attendeesAccepted: [tarekId],
            attendeesInvited: [aliId],
            host: tarekId
        ),
        EventModel(
            id: "3",
            title: "Coffee Date",
            location: "Old Soul",
            startDateTime: Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 6, hour: 11, minute: 10))!,
            endDateTime: Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 6, hour: 11, minute: 10))!,
            attendeesAccepted: [aliId],
            attendeesInvited: [tarekId],
            host: aliId
        ),
//        EventModel(
//            id: "4",
//            title: "Valentines",
//            location: "Firehouse",
//            date: "2025-02-20",
//            time: "9 AM",
//            attendeesAccepted: ["tareksakakini"],
//            attendeesInvited: []
//        ),
//        EventModel(
//            id: "5",
//            title: "Snowshoeing",
//            location: "Palisades",
//            date: "2025-02-10",
//            time: "7 PM",
//            attendeesAccepted: ["tareksakakini"],
//            attendeesInvited: []
//        ),
//        EventModel(
//            id: "6",
//            title: "Dinner",
//            location: "Cheesecake Factory",
//            date: "2025-01-30",
//            time: "4 PM",
//            attendeesAccepted: ["tareksakakini"],
//            attendeesInvited: []
//        ),
//        EventModel(
//            id: "7",
//            title: "Play Date",
//            location: "Fulton's",
//            date: "2025-02-20",
//            time: "9 AM",
//            attendeesAccepted: ["tareksakakini"],
//            attendeesInvited: []
//        ),
//        EventModel(
//            id: "8",
//            title: "Bike Ride",
//            location: "American River",
//            date: "2025-02-10",
//            time: "7 PM",
//            attendeesAccepted: ["tareksakakini"],
//            attendeesInvited: []
//        ),
//        EventModel(
//            id: "9",
//            title: "Bungee Jumping",
//            location: "Oregon",
//            date: "2025-01-30",
//            time: "4 PM",
//            attendeesAccepted: ["tareksakakini"],
//            attendeesInvited: []
//        ),
//        EventModel(
//            id: "10",
//            title: "Movie Night",
//            location: "Home",
//            date: "2025-02-20",
//            time: "9 AM",
//            attendeesAccepted: ["tareksakakini"],
//            attendeesInvited: []
//        ),
//        EventModel(
//            id: "11",
//            title: "Rafting",
//            location: "Yosemite",
//            date: "2025-02-10",
//            time: "7 PM",
//            attendeesAccepted: [],
//            attendeesInvited: ["tareksakakini"]
//        ),
//        EventModel(
//            id: "12",
//            title: "Hiking",
//            location: "Lake Tahoe",
//            date: "2025-01-30",
//            time: "4 PM",
//            attendeesAccepted: [],
//            attendeesInvited: ["tareksakakini"]
//        ),
//        EventModel(
//            id: "13",
//            title: "BBQ",
//            location: "William Pond Park",
//            date: "2025-02-20",
//            time: "9 AM",
//            attendeesAccepted: [],
//            attendeesInvited: ["tareksakakini"]
//        ),
//        EventModel(
//            id: "14",
//            title: "Soccer",
//            location: "Cal Middle School",
//            date: "2025-02-10",
//            time: "7 PM",
//            attendeesAccepted: [],
//            attendeesInvited: ["tareksakakini"]
//        ),
//        EventModel(
//            id: "15",
//            title: "Pickleball",
//            location: "Del Norte",
//            date: "2025-01-30",
//            time: "4 PM",
//            attendeesAccepted: [],
//            attendeesInvited: ["tareksakakini"]
//        )
    ]
}
