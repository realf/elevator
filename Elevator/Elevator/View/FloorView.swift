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

    static let floorFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: control.stopAtFloor == floor ? "door.french.open" : "door.french.closed")
                .font(.title)

            Text("\(floor)")
                .font(.body)

            Button {
                if !isCalled {
                    control.callOnFloor(floor)
                }
            } label: {
                Image(systemName: "button.programmable")
            }
            .roundButton(backgroundColor: isCalled ? Color.orange : Color.gray)
        }
    }
}


struct BlueButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color(red: 0, green: 0, blue: 0.5))
            .foregroundStyle(.white)
            .clipShape(Capsule())
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
