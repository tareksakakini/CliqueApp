//
//  UserData.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/23/25.
//

import Foundation

struct UserData {
    static let userData: [UserModel] = [
        UserModel(
            firstName: "Tarek",
            lastName: "Sakakini",
            userName: "tareksakakini",
            password: "adeeb",
            eventsAccepted: ["1", "2"],
            eventsInvited: ["3"]
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
        )
    ]
}
