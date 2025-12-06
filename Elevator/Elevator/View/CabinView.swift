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
        VStack {
            Text("Cabin")
                .font(.title3)
            
            ScrollView {
                VStack(alignment: .trailing, spacing: 8) {
                    ForEach(control.floorButtonPressedStates, id: \.self) { button in
                        Button {
                            control.pressFloorInCabin(button.floor)
                        } label: {
                            Text("\(button.floor)")
                        }
                        .roundButton(backgroundColor: button.isPressed ? Color.orange : Color.gray)
                    }
                    .disabled(control.floorButtonsDisabled)
                }
            }
        }
    }
}

#Preview {
    CabinView(control: ElevatorState(minFloor: -1, maxFloor: 9))
}
