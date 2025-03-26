//
//  UserData.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/23/25.
//

import Foundation

struct UserData {
    
    static var friendshipData: [String: [String]] = [
        "tareksakakini@gmail.com": ["alikanj@gmail.com", "hassandbouk@gmail.com", "mohamadelhajj@gmail.com"],
        "hassandbouk@gmail.com": ["tareksakakini@gmail.com", "jadyaacoub@gmail.com"],
        "jadyaacoub@gmail.com": ["hassandbouk@gmail.com"],
        "mohamadelhajj@gmail.com": ["tareksakakini@gmail.com"],
        "alikanj@gmail.com": ["tareksakakini@gmail.com"]
    ]
    
    static var friendInviteReceived: [String: [String]] = [
        "tareksakakini@gmail.com": ["jadyaacoub@gmail.com"]
    ]
        
    static var userData: [UserModel] = [
        UserModel(
            fullname: "Tarek Sakakini",
            email: "tarek.sakakini@gmail.com",
            createdAt: Date(),
            profilePic: "tarek_pic"
        ),
        UserModel(
            fullname: "Ali Kanj",
            email: "alikanj@gmail.com",
            createdAt: Date()
        ),
        UserModel(
            fullname: "Hassan Dbouk",
            email: "hassandbouk@gmail.com",
            createdAt: Date()
        ),
        UserModel(
            fullname: "Mohamad El Hajj",
            email: "mohamadelhajj@gmail.com",
            createdAt: Date()
        ),
        UserModel(
            fullname: "Jad Yaacoub",
            email: "jadyaacoub@gmail.com",
            createdAt: Date()
        )
    ]
    
    static var eventData: [EventModel] = [
        EventModel(
            id: "1",
            title: "Snowboarding",
            location: "Northstar",
            dateTime: Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 5, hour: 11, minute: 10))!,
            attendeesAccepted: ["tareksakakini@gmail.com", "alikanj@gmail.com"],
            attendeesInvited: ["jadyaacoub@gmail.com", "testing3@testing.com"],
            host: "tareksakakini@gmail.com"
        ),
        EventModel(
            id: "2",
            title: "Board Game Night",
            location: "George and Marias",
            dateTime: Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 4, hour: 11, minute: 10))!,
            attendeesAccepted: ["tareksakakini@gmail.com"],
            attendeesInvited: ["alikanj@gmail.com"],
            host: "tareksakakini@gmail.com"
        ),
        EventModel(
            id: "3",
            title: "Coffee Date",
            location: "Old Soul",
            dateTime: Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 6, hour: 11, minute: 10))!,
            attendeesAccepted: ["alikanj@gmail.com"],
            attendeesInvited: ["tareksakakini@gmail.com"],
            host: "alikanj@gmail.com"
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
