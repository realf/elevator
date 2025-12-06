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

    private var _direction: Direction?
    private var _isPowerOn = true
    private var _currentFloor = 1.0
    private var _stopAtFloor: Int?

    private var _floorsPressedInCabin: Set<Int> = []
    private var _floorsCalled: Set<Int> = []

    private let step = 0.05
    private let stateLock = NSRecursiveLock()

    init(minFloor: Int, maxFloor: Int) {
        self.minFloor = minFloor
        self.maxFloor = maxFloor
    }

    private func call(floor: Int, controlPanel: ControlPanel) {
        stateLock.withLock {
            guard abs(self._currentFloor - Double(floor)) > step else { return }

            switch controlPanel {
            case .cabin:
                self._floorsPressedInCabin.insert(floor)
            case .floor:
                self._floorsCalled.insert(floor)
            }
            self._startMovingIfCan()
        }
    }

    private func _startMovingIfCan() {
        guard self._direction == nil else { return }

        if let pressedInCabinFloor = self._nearestPressedInCabinFloor(
            from: self._currentFloor
        ) {
            self._direction = self._direction(
                from: _currentFloor,
                to: pressedInCabinFloor
            )
        }

        if self._direction == nil {
            if let calledFloor = self._nearestCalledFloor(
                from: self._currentFloor
            ) {
                self._direction = self._direction(
                    from: _currentFloor,
                    to: calledFloor
                )
            }
        }

        self._move()
    }

    private func _move() {
        let hasCalls =
            !self._floorsCalled.isEmpty || !self._floorsPressedInCabin.isEmpty

        guard self._isPowerOn && hasCalls else {
            self._direction = nil
            return
        }

        guard let direction = self._direction else {
            return
        }

        switch direction {
        case .up:
            self._currentFloor += step
        case .down:
            self._currentFloor -= step
        }

        self._currentFloor = min(
            max(self._currentFloor, Double(minFloor)),
            Double(maxFloor)
        )

        let action = self._nextAction()
        Task {
            switch action {
            case .continueMoving:
                try? await Task.sleep(for: .milliseconds(100))
                stateLock.withLock {
                    self._move()
                }
            case .openDoors:
                stateLock.withLock {
                    self._stopAtFloor = Int(round(_currentFloor))
                }
                try? await Task.sleep(for: .milliseconds(2000))
                stateLock.withLock {
                    self._stopAtFloor = nil
                    self._move()
                }
            case .processCalls:
                stateLock.withLock {
                    self._direction = nil
                    self._startMovingIfCan()
                }
            }
        }
    }

    private func _nextAction() -> Action {
        switch self._direction {
        case .down:
            let pressedInCabinFloor = self._nearestPressedInCabinFloor(
                from: self._currentFloor
            )
            let calledFloor = self._nearestCalledFloor(
                from: self._currentFloor
            )

            let floors = Set(
                [pressedInCabinFloor, calledFloor].compactMap(\.self)
            )
            let floor = self._nearestFloor(
                from: self._currentFloor,
                in: floors
            )

            guard let floor else {
                return .processCalls
            }

            return _tryOpenDoors(floor: floor)

        case .up:
            let pressedInCabinFloor = self._nearestPressedInCabinFloor(
                from: self._currentFloor
            )

            if let pressedInCabinFloor {
                return _tryOpenDoors(floor: pressedInCabinFloor)
            }

            let calledFloor = self._nearestCalledFloor(
                from: self._currentFloor
            )

            if let calledFloor {
                return _tryOpenDoors(floor: calledFloor)
            }
            return .processCalls

        case .none:
            return .processCalls
        }
    }

    private func _tryOpenDoors(floor: Int) -> Action {
        if abs(self._currentFloor - Double(floor)) < self.step {
            self._floorsPressedInCabin.remove(floor)
            self._floorsCalled.remove(floor)
            return .openDoors
        }
        return .continueMoving
    }

    private func _nearestPressedInCabinFloor(from floor: Double) -> Int? {
        return _nearestFloor(from: floor, in: _floorsPressedInCabin)
    }

    private func _nearestCalledFloor(from floor: Double) -> Int? {
        return _nearestFloor(from: floor, in: _floorsCalled)
    }

    private func _nearestFloor(from floor: Double, in floors: Set<Int>) -> Int?
    {
        floors
            .compactMap {
                switch _direction {
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

    private func _direction(from fromFloor: Double, to toFloor: Int)
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
        stateLock.withLock {
            let pressedButtons =
                switch control {
                case .cabin:
                    self._floorsPressedInCabin
                case .floor:
                    self._floorsCalled
                }

            return Array(minFloor...maxFloor)
                .reversed()
                .map { floor in
                    let isPressed = pressedButtons.contains(floor)
                    return ButtonState(floor: floor, isPressed: isPressed)
                }
        }
    }
}

extension ElevatorState: FloorControl {
    var stopAtFloor: Int? {
        stateLock.withLock {
            _stopAtFloor
        }
    }

    func callOnFloor(_ floor: Int) {
        call(floor: floor, controlPanel: .floor)
    }

    var floorsCalledStates: [ButtonState] {
        buttonPressedStates(control: .floor)
    }
}

extension ElevatorState: DispatcherControl {
    var closestFloor: Int {
        stateLock.withLock {
            Int(round(_currentFloor))
        }
    }

    var direction: Direction? {
        stateLock.withLock {
            _direction
        }
    }

    var currentFloor: Double {
        get {
            stateLock.withLock { _currentFloor }
        }
        set {
            stateLock.withLock { _currentFloor = newValue }
        }
    }

    var isPowerOn: Bool {
        stateLock.withLock {
            _isPowerOn
        }
    }

    func togglePower() {
        stateLock.withLock {
            self._isPowerOn.toggle()

            if !self._isPowerOn {
                _floorsPressedInCabin.removeAll()
                _floorsCalled.removeAll()
            }
        }
    }
}
