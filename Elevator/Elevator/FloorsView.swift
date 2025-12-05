//
//  FloorsView.swift
//  Elevator
//
//  Created by alf on 05.12.2025.
//

import SwiftUI

struct FloorsView: View {
    let floors: FloorControl

    var body: some View {
        VStack {
            Text("Floors")
                .font(.title3)

            ScrollView {
                VStack(alignment: .trailing, spacing: 8) {
                    ForEach(floors.floorsCalledStates.enumerated(), id: \.offset) {
                        index,
                        button in
                        FloorView(
                            control: floors,
                            isCalled: button.isPressed,
                            floor: button.floor
                        )
                    }
                    .disabled(floors.floorButtonsDisabled)
                }
            }
        }
    }
}

#Preview {
    FloorsView(floors: ElevatorState(minFloor: 1, maxFloor: 9))
}
