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

    static let floorFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()

    var body: some View {
        HStack {
            DirectionView(direction: control.direction)
            Text(
                "Elevator on\nthe \(Self.floorFormatter.string(from: NSNumber(value: control.closestFloor)) ?? "?") floor"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Button {
                if !isCalled {
                    control.callOnFloor(floor)
                }
            } label: {
                Text(isCalled ? "Wait" : "Call")
            }
            .buttonStyle(.bordered)
            .foregroundStyle(Color.primary)
            .background(
                isCalled ? Color.orange : Color.gray
            )
            .clipShape(Capsule())
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
