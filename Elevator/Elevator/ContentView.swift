//
//  ContentView.swift
//  Elevator
//
//  Created by alf on 05.12.2025.
//

import SwiftUI

struct ContentView: View {
    let elevatorState = ElevatorState(
        minFloor: 1,
        maxFloor: 9,
        queue: DispatchQueue(label: "Elevator 1")
    )

    var body: some View {
        VStack {
            HStack(spacing: 80) {
                VStack {
                    Text("Cabin")
                    CabinView(control: elevatorState)
                }

                VStack {
                    Text("Floors")
                        .padding(.bottom, 8)
                    FloorsView(floors: elevatorState, spacing: 13.5)
                }
            }

            Spacer()

            VStack {
                Text("Dispatch Room")
                DispatcherView(control: elevatorState)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
