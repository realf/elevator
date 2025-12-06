//
//  ContentView.swift
//  Elevator
//
//  Created by alf on 05.12.2025.
//

import SwiftUI

struct ContentView: View {
    let elevatorState: ElevatorState

    var body: some View {
        VStack {
            HStack(spacing: 40) {
                FloorsView(floors: elevatorState)
                Divider()
                CabinView(control: elevatorState)
            }

            Divider()

            DispatcherView(control: elevatorState)
        }
        .padding()
    }
}

#Preview {
    ContentView(elevatorState: ElevatorState(minFloor: 1, maxFloor: 9))
}
