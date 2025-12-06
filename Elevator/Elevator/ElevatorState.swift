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
    let minFloor: Int
    let maxFloor: Int

    private var _direction: Direction?
    private var _isPowerOn = true
    private var _currentFloor = 1.0
    private var _stopAtFloor: Int?

    private var _floorsPressedInCabin: Set<Int> = []
    private var _floorsCalled: Set<Int> = []

    private let step = 0.05
    private let stateLock = NSLock()

    enum Action {
        case continueMoving
        case openDoors
        case processCalls
    }

    init(minFloor: Int, maxFloor: Int) {
        self.minFloor = minFloor
        self.maxFloor = maxFloor
    }

    private func _nextAction() -> Action {
        let pressedInCabinFloor = self._nearestPressedInCabinFloor(
            from: self._currentFloor
        )
        let calledFloor = self._nearestCalledFloor(
            from: self._currentFloor
        )

        switch self._direction {
        case .down:
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

            return _tryOpenDoors(floor: floor) ? .openDoors : .continueMoving

        case .up:
            if let pressedInCabinFloor {
                return _tryOpenDoors(floor: pressedInCabinFloor)
                    ? .openDoors : .continueMoving
            } else if let calledFloor {
                return _tryOpenDoors(floor: calledFloor)
                    ? .openDoors : .continueMoving
            }
            return .processCalls

        case .none:
            return .processCalls
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
            // Delay to emulate opened and closed doors or elevator movement
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
                try? await Task.sleep(for: .milliseconds(1000))
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

    private func _tryOpenDoors(floor: Int) -> Bool {
        if abs(self._currentFloor - Double(floor)) < self.step {
            self._floorsPressedInCabin.remove(floor)
            self._floorsCalled.remove(floor)
            return true
        }
        return false
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
        stateLock.withLock {
            Array(minFloor...maxFloor)
                .reversed()
                .map { floor in
                    let isPressed = self._floorsPressedInCabin.contains(floor)
                    return ButtonState(floor: floor, isPressed: isPressed)
                }
        }
    }

    var floorButtonsDisabled: Bool {
        !isPowerOn
    }

    func pressFloorInCabin(_ floor: Int) {
        stateLock.withLock { [weak self] in
            guard let self else { return }
            guard !self._floorsPressedInCabin.contains(floor) else { return }

            self._floorsPressedInCabin.insert(floor)
            self._startMovingIfCan()
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
        stateLock.withLock { [weak self] in
            guard let self else { return }
            guard !self._floorsCalled.contains(floor) else { return }

            self._floorsCalled.insert(floor)
            self._startMovingIfCan()
        }
    }

    var floorsCalledStates: [ButtonState] {
        stateLock.withLock {
            Array(minFloor...maxFloor)
                .reversed()
                .map { floor in
                    let isPressed = self._floorsCalled.contains(floor)
                    return ButtonState(floor: floor, isPressed: isPressed)
                }
        }
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
            stateLock.withLock {
                _currentFloor
            }
        }
        set {
            stateLock.withLock { [weak self] in
                self?._currentFloor = newValue
            }
        }
    }

    var isPowerOn: Bool {
        stateLock.withLock {
            _isPowerOn
        }
    }

    func togglePower() {
        stateLock.withLock { [weak self] in
            guard let self else { return }
            self._isPowerOn.toggle()

            if !self._isPowerOn {
                _floorsPressedInCabin.removeAll()
                _floorsCalled.removeAll()
            }
        }
    }
}
