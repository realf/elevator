//
//  FloorView.swift
//  Elevator
//
//  Created by alf on 05.12.2025.
//

import SwiftUI

struct FloorView: View {
    let control: FloorControl
    let isCalled: Bool
    let floor: Int
    let buttonSize = 44.0

    var body: some View {
        HStack(spacing: 20) {
            Text("\(floor)")
                .bold()
                .foregroundStyle(
                    floor == Int(round(control.currentFloor))
                        ? Color.orange : Color.gray
                )

            Button {
                if !isCalled {
                    control.callOnFloor(floor)
                }
            } label: {
                Image(systemName: "button.programmable")
            }
            .roundButton(backgroundColor: isCalled ? Color.orange : Color.gray)

            let doorsOpen = control.doorsOpenAtFloor == floor

            Image(
                systemName: doorsOpen
                    ? "door.french.open" : "door.french.closed"
            )
            .foregroundStyle(Color.gray)
            .font(.title)
            .bold()
        }
    }
}

#Preview {
    FloorView(
        control: ElevatorState(minFloor: 1, maxFloor: 9),
        isCalled: true,
        floor: 3
    )
}

#Preview {
    FloorView(
        control: ElevatorState(minFloor: 1, maxFloor: 9),
        isCalled: false,
        floor: 5
    )
}
