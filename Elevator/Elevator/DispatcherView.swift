//
//  DispatcherView.swift
//  Elevator
//
//  Created by alf on 05.12.2025.
//

import SwiftUI

struct DispatcherView: View {
    let elevatorState: ElevatorState
    var body: some View {
        Button {
            elevatorState.togglePower()
        } label: {
            Text("Toggle Power")
        }

        Text("Elevator power: \(elevatorState.isPowerOn ? "On" : "Off")")
    }
}

#Preview {
    DispatcherView(elevatorState: ElevatorState(minFloor: 1, maxFloor: 9))
}
