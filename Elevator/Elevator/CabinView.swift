//
//  CabinView.swift
//  Elevator
//
//  Created by alf on 05.12.2025.
//

import SwiftUI

struct CabinView: View {
    let control: CabinControl

    var body: some View {
        ScrollView {
            VStack {
                ForEach(control.floorButtonPressedStates, id: \.self) { button in
                    Button {
                        control.pressFloorInCabin(button.floor)
                    } label: {
                        Text("\(button.floor)")
                    }
                    .frame(width: 44, height: 44)
                    .background(button.isPressed ? Color.orange : Color.gray)
                    .foregroundStyle(Color.white)
                    .clipShape(Circle())
                }
                .disabled(control.floorButtonsDisabled)
            }
        }
    }
}

#Preview {
    CabinView(control: ElevatorState(minFloor: -1, maxFloor: 9))
}
