//
//  ElevatorApp.swift
//  Elevator
//
//  Created by alf on 05.12.2025.
//

import SwiftUI

@main
struct ElevatorApp: App {
    let elecatorState: ElevatorState = .init(minFloor: 1, maxFloor: 9)

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
