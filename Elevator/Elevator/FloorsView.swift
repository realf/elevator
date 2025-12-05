//
//  FloorsView.swift
//  Elevator
//
//  Created by alf on 05.12.2025.
//

import SwiftUI

struct FloorsView: View {
    let floors: Floors & FloorControl
    let spacing: CGFloat

    var body: some View {
        ScrollView {
            ForEach(floors.floorsCalledStates, id: \.self) { button in
                FloorView(
                    control: floors,
                    isCalled: button.isPressed,
                    floor: button.floor
                )
                .padding(.bottom, spacing)

            }
        }
    }
}

#Preview {
    FloorsView(floors: ElevatorState(minFloor: 1, maxFloor: 9), spacing: 0)
}
