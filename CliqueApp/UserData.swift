//
//  UserData.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/23/25.
//

import Foundation

struct UserData {
    
    static let friendshipData: [String: [String]] = [
        "tareksakakini": ["alikanj", "hassandbouk", "mohamadelhajj"],
        "hassandbouk": ["tareksakakini", "jadyaacoub"],
        "jadyaacoub": ["hassandbouk"],
        "mohamadelhajj": ["tareksakakini"],
        "alikanj": ["tareksakakini"]
    ]
    
    static let userData: [UserModel] = [
        UserModel(
            firstName: "Tarek",
            lastName: "Sakakini",
            userName: "tareksakakini",
            password: "adeeb",
            eventsAccepted: ["1", "2", "4", "5", "6", "7", "8", "9", "10"],
            eventsInvited: ["3", "11", "12", "13", "14", "15"]
        ),
        UserModel(
            firstName: "Ali",
            lastName: "Kanj",
            userName: "alikanj",
            password: "adeeb",
            eventsAccepted: ["1", "3"],
            eventsInvited: ["2"]
        ),
        UserModel(
            firstName: "Hassan",
            lastName: "Dbouk",
            userName: "hassandbouk",
            password: "adeeb",
            eventsAccepted: [],
            eventsInvited: []
        ),
        UserModel(
            firstName: "Mohamad",
            lastName: "El Hajj",
            userName: "mohamadelhajj",
            password: "adeeb",
            eventsAccepted: [],
            eventsInvited: []
        ),
        UserModel(
            firstName: "Jad",
            lastName: "Yaacoub",
            userName: "jadyaacoub",
            password: "adeeb",
            eventsAccepted: [],
            eventsInvited: []
        )
    ]
    
    static let eventData: [EventModel] = [
        EventModel(
            id: "1",
            title: "Snowboarding",
            location: "Northstar",
            date: "2025-02-20",
            time: "9 AM",
            attendeesAccepted: ["tareksakakini", "alikanj"],
            attendeesInvited: []
        ),
        EventModel(
            id: "2",
            title: "Board Game Night",
            location: "George and Marias",
            date: "2025-02-10",
            time: "7 PM",
            attendeesAccepted: ["tareksakakini"],
            attendeesInvited: ["alikanj"]
        ),
        EventModel(
            id: "3",
            title: "Coffee Date",
            location: "Old Soul",
            date: "2025-01-30",
            time: "4 PM",
            attendeesAccepted: ["alikanj"],
            attendeesInvited: ["tareksakakini"]
        ),
        EventModel(
            id: "4",
            title: "Valentines",
            location: "Firehouse",
            date: "2025-02-20",
            time: "9 AM",
            attendeesAccepted: ["tareksakakini"],
            attendeesInvited: []
        ),
        EventModel(
            id: "5",
            title: "Snowshoeing",
            location: "Palisades",
            date: "2025-02-10",
            time: "7 PM",
            attendeesAccepted: ["tareksakakini"],
            attendeesInvited: []
        ),
        EventModel(
            id: "6",
            title: "Dinner",
            location: "Cheesecake Factory",
            date: "2025-01-30",
            time: "4 PM",
            attendeesAccepted: ["tareksakakini"],
            attendeesInvited: []
        ),
        EventModel(
            id: "7",
            title: "Play Date",
            location: "Fulton's",
            date: "2025-02-20",
            time: "9 AM",
            attendeesAccepted: ["tareksakakini"],
            attendeesInvited: []
        ),
        EventModel(
            id: "8",
            title: "Bike Ride",
            location: "American River",
            date: "2025-02-10",
            time: "7 PM",
            attendeesAccepted: ["tareksakakini"],
            attendeesInvited: []
        ),
        EventModel(
            id: "9",
            title: "Bungee Jumping",
            location: "Oregon",
            date: "2025-01-30",
            time: "4 PM",
            attendeesAccepted: ["tareksakakini"],
            attendeesInvited: []
        ),
        EventModel(
            id: "10",
            title: "Movie Night",
            location: "Home",
            date: "2025-02-20",
            time: "9 AM",
            attendeesAccepted: ["tareksakakini"],
            attendeesInvited: []
        ),
        EventModel(
            id: "11",
            title: "Rafting",
            location: "Yosemite",
            date: "2025-02-10",
            time: "7 PM",
            attendeesAccepted: [],
            attendeesInvited: ["tareksakakini"]
        ),
        EventModel(
            id: "12",
            title: "Hiking",
            location: "Lake Tahoe",
            date: "2025-01-30",
            time: "4 PM",
            attendeesAccepted: [],
            attendeesInvited: ["tareksakakini"]
        ),
        EventModel(
            id: "13",
            title: "BBQ",
            location: "William Pond Park",
            date: "2025-02-20",
            time: "9 AM",
            attendeesAccepted: [],
            attendeesInvited: ["tareksakakini"]
        ),
        EventModel(
            id: "14",
            title: "Soccer",
            location: "Cal Middle School",
            date: "2025-02-10",
            time: "7 PM",
            attendeesAccepted: [],
            attendeesInvited: ["tareksakakini"]
        ),
        EventModel(
            id: "15",
            title: "Pickleball",
            location: "Del Norte",
            date: "2025-01-30",
            time: "4 PM",
            attendeesAccepted: [],
            attendeesInvited: ["tareksakakini"]
        )
    ]
}
