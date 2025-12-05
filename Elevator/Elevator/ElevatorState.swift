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

    private var _floorsPressedInCabin: Set<Int> = []
    private var _floorsCalled: Set<Int> = []

    private let moveStep = 0.1
    private let stateLock = NSLock()

    init(minFloor: Int, maxFloor: Int) {
        self.minFloor = minFloor
        self.maxFloor = maxFloor
    }

    private func _move() {
        guard self._isPowerOn else { return }

        let nearestPressedFloor = self._nearestPressedFloor(
            from: self._currentFloor
        )
        let nearestCalledFloor = self._nearestCalledFloor(
            from: self._currentFloor
        )

        switch self._direction {
        case .down:
            let floors = Set(
                [nearestPressedFloor, nearestCalledFloor].compactMap(\.self)
            )
            if let floor = self._nearestFloor(
                from: self._currentFloor,
                in: floors
            ) {
                self._moveTo(floor: floor)
            }

        case .up:
            if let nearestPressedFloor {
                self._moveTo(floor: nearestPressedFloor)
            } else if let nearestCalledFloor {
                self._moveTo(floor: nearestCalledFloor)
            }

        case .none:
            if let nearestPressedFloor {
                self._direction = _direction(
                    from: _currentFloor,
                    to: nearestPressedFloor
                )
                self._moveTo(floor: nearestPressedFloor)
            } else if let nearestCalledFloor {
                self._direction = _direction(
                    from: _currentFloor,
                    to: nearestCalledFloor
                )
                self._moveTo(floor: nearestCalledFloor)
            }
        }
    }

    private func _moveTo(floor: Int) {
        if abs(self._currentFloor - Double(floor)) < self.moveStep {
            self._floorsPressedInCabin.remove(floor)
            self._floorsCalled.remove(floor)

            if self._floorsCalled.isEmpty && self._floorsPressedInCabin.isEmpty
            {
                _direction = nil
            }
        }
        moveIncrementally()
    }

    private func moveIncrementally() {
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            stateLock.withLock {
                if self._direction == .up {
                    self._currentFloor += 0.1
                } else if self._direction == .down {
                    self._currentFloor -= 0.1
                }
                self._move()
            }
        }
    }

    private func _nearestPressedFloor(from floor: Double) -> Int? {
        return _nearestFloor(from: floor, in: _floorsPressedInCabin)
    }

    private func _nearestCalledFloor(from floor: Double) -> Int? {
        return _nearestFloor(from: floor, in: _floorsCalled)
    }

    private func _nearestFloor(from floor: Double, in floors: Set<Int>)
        -> Int?
    {
        floors
            .compactMap {
                switch _direction {
                case .down:
                    Double($0) < floor ? $0 : nil
                case .up:
                    Double($0) > floor ? $0 : nil
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
            self._floorsPressedInCabin.insert(floor)
            self._move()
        }
    }
}

extension ElevatorState: FloorControl {
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

    func callOnFloor(_ floor: Int) {
        stateLock.withLock { [weak self] in
            guard let self else { return }
            self._floorsCalled.insert(floor)
            self._move()
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
                self._direction = nil
                _floorsPressedInCabin.removeAll()
                _floorsCalled.removeAll()
            }
        }
    }
}
