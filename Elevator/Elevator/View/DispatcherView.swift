//
//  DispatcherView.swift
//  Elevator
//
//  Created by alf on 05.12.2025.
//

import SwiftUI

struct DispatcherView: View {
    let control: DispatcherControl

    var body: some View {
        VStack(spacing: 32) {
            let floorRange =
                Double(control.minFloor)...Double(control.maxFloor)

                HStack(spacing: 20) {
                    Group {
                        Gauge(
                            value: control.currentFloor,
                            in: floorRange
                        ) {
                            Text("Floor")
                        } currentValueLabel: {
                            Text("\(control.closestFloor)")
                        } minimumValueLabel: {
                            Text("\(control.minFloor)")
                        } maximumValueLabel: {
                            Text("\(control.maxFloor)")
                        }
                        .gaugeStyle(.accessoryCircular)

                        DirectionView(direction: control.direction)
                            .font(.system(size: 28))


                        let boltStyle: (name: String, color: Color) = control.isPowerOn
                        ? ("bolt", Color.green)
                        : ("bolt.slash", Color.blue)

                        Image(systemName: boltStyle.name)
                            .foregroundStyle(boltStyle.color)
                            .font(.system(size: 42))
                    }
                }

                Button {
                    control.togglePower()
                } label: {
                    Image(systemName: "power")
                        .foregroundStyle(Color.red)
                }
                .font(.title)
                .buttonStyle(.bordered)
        }
    }
}

#Preview {
    DispatcherView(control: ElevatorState(minFloor: 1, maxFloor: 9))
}
