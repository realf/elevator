//
//  ElevatorState.swift
//  Elevator
//
//  Created by alf on 05.12.2025.
//

import Foundation
import SwiftUI

enum Direction {
    case up
    case down
}

struct ButtonState: Hashable {
    var floor: Int
    var isPressed: Bool
}

protocol CabinControl: Observable {
    var floorButtonPressedStates: [ButtonState] { get }
    var floorButtonsDisabled: Bool { get }

    func pressFloorInCabin(_ floor: Int)
}

protocol FloorControl: Observable {
    var floorButtonsDisabled: Bool { get }
    var floorsCalledStates: [ButtonState] { get }
    var stopAtFloor: Int? { get }

    func callOnFloor(_ floor: Int)
}

protocol DispatcherControl: Observable {
    var isPowerOn: Bool { get }
    var currentFloor: Double { get }
    var closestFloor: Int { get }
    var minFloor: Int { get }
    var maxFloor: Int { get }
    var direction: Direction? { get }

    func togglePower()
}

@Observable
class ElevatorState {
    private enum Action {
        case continueMoving
        case openDoors
        case processCalls
    }

    private enum ControlPanel {
        case cabin
        case floor
    }

    let minFloor: Int
    let maxFloor: Int

    private(set) var direction: Direction?
    private(set) var isPowerOn = true
    private(set) var currentFloor = 1.0
    private(set) var stopAtFloor: Int?

    private(set) var floorsPressedInCabin: Set<Int> = []
    private(set) var floorsCalled: Set<Int> = []

    private let step = 0.05

    init(minFloor: Int, maxFloor: Int) {
        self.minFloor = minFloor
        self.maxFloor = maxFloor
    }

    private func call(floor: Int, controlPanel: ControlPanel) {
        guard abs(self.currentFloor - Double(floor)) > step else { return }

        switch controlPanel {
        case .cabin:
            self.floorsPressedInCabin.insert(floor)
        case .floor:
            self.floorsCalled.insert(floor)
        }
        self.startMovingIfCan()
    }

    private func startMovingIfCan() {
        guard self.direction == nil else { return }

        if let pressedInCabinFloor = self.nearestPressedInCabinFloor(
            from: self.currentFloor
        ) {
            self.direction = self.direction(
                from: currentFloor,
                to: pressedInCabinFloor
            )
        }

        if self.direction == nil {
            if let calledFloor = self.nearestCalledFloor(
                from: self.currentFloor
            ) {
                self.direction = self.direction(
                    from: currentFloor,
                    to: calledFloor
                )
            }
        }

        self.move()
    }

    private func move() {
        let hasCalls =
            !self.floorsCalled.isEmpty || !self.floorsPressedInCabin.isEmpty

        guard self.isPowerOn && hasCalls else {
            self.direction = nil
            return
        }

        guard let direction = self.direction else {
            return
        }

        switch direction {
        case .up:
            self.currentFloor += step
        case .down:
            self.currentFloor -= step
        }

        self.currentFloor = min(
            max(self.currentFloor, Double(minFloor)),
            Double(maxFloor)
        )

        let action = self.nextAction()
        Task { [weak self] in
            guard let self else { return }
            
            switch action {
            case .continueMoving:
                try? await Task.sleep(for: .milliseconds(100))
                self.move()
            case .openDoors:
                self.stopAtFloor = Int(round(self.currentFloor))
                try? await Task.sleep(for: .milliseconds(2000))
                self.stopAtFloor = nil
                self.move()
            case .processCalls:
                self.direction = nil
                self.startMovingIfCan()
            }
        }
    }

    private func nextAction() -> Action {
        switch self.direction {
        case .down:
            let pressedInCabinFloor = self.nearestPressedInCabinFloor(
                from: self.currentFloor
            )
            let calledFloor = self.nearestCalledFloor(
                from: self.currentFloor
            )

            let floors = Set(
                [pressedInCabinFloor, calledFloor].compactMap(\.self)
            )
            let floor = self.nearestFloor(
                from: self.currentFloor,
                in: floors
            )

            guard let floor else {
                return .processCalls
            }

            return tryOpenDoors(floor: floor)

        case .up:
            let pressedInCabinFloor = self.nearestPressedInCabinFloor(
                from: self.currentFloor
            )

            if let pressedInCabinFloor {
                return tryOpenDoors(floor: pressedInCabinFloor)
            }

            let calledFloor = self.nearestCalledFloor(
                from: self.currentFloor
            )

            if let calledFloor {
                return tryOpenDoors(floor: calledFloor)
            }
            return .processCalls

        case .none:
            return .processCalls
        }
    }

    private func tryOpenDoors(floor: Int) -> Action {
        if abs(self.currentFloor - Double(floor)) < self.step {
            self.floorsPressedInCabin.remove(floor)
            self.floorsCalled.remove(floor)
            return .openDoors
        }
        return .continueMoving
    }

    private func nearestPressedInCabinFloor(from floor: Double) -> Int? {
        return nearestFloor(from: floor, in: floorsPressedInCabin)
    }

    private func nearestCalledFloor(from floor: Double) -> Int? {
        return nearestFloor(from: floor, in: floorsCalled)
    }

    private func nearestFloor(from floor: Double, in floors: Set<Int>) -> Int? {
        floors
            .compactMap {
                switch direction {
                case .down:
                    Double($0) <= floor ? $0 : nil
                case .up:
                    Double($0) >= floor ? $0 : nil
                case .none:
                    $0
                }
            }.min {
                abs(Double($0) - floor) < abs(Double($1) - floor)
            }
    }

    private func direction(from fromFloor: Double, to toFloor: Int)
        -> Direction
    {
        return fromFloor < Double(toFloor) ? .up : .down
    }
}

extension ElevatorState: CabinControl {
    var floorButtonPressedStates: [ButtonState] {
        buttonPressedStates(control: .cabin)
    }

    var floorButtonsDisabled: Bool {
        !isPowerOn
    }

    func pressFloorInCabin(_ floor: Int) {
        call(floor: floor, controlPanel: .cabin)
    }

    private func buttonPressedStates(control: ControlPanel) -> [ButtonState] {
        let pressedButtons =
            switch control {
            case .cabin:
                self.floorsPressedInCabin
            case .floor:
                self.floorsCalled
            }

        return Array(minFloor...maxFloor)
            .reversed()
            .map { floor in
                let isPressed = pressedButtons.contains(floor)
                return ButtonState(floor: floor, isPressed: isPressed)
            }
    }
}

extension ElevatorState: FloorControl {
    func callOnFloor(_ floor: Int) {
        call(floor: floor, controlPanel: .floor)
    }

    var floorsCalledStates: [ButtonState] {
        buttonPressedStates(control: .floor)
    }
}

extension ElevatorState: DispatcherControl {
    var closestFloor: Int {
        Int(round(currentFloor))
    }

    func togglePower() {
        self.isPowerOn.toggle()

        if !self.isPowerOn {
            floorsPressedInCabin.removeAll()
            floorsCalled.removeAll()
        }
    }
}
