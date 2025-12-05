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
    var closestFloor: Int { get }
    var direction: Direction? { get }

    func callOnFloor(_ floor: Int)
}

protocol Floors: Observable {
    var floorsCalledStates: [ButtonState] { get }
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

    private let queue: DispatchQueue

    init(
        minFloor: Int,
        maxFloor: Int,
        queue: DispatchQueue = DispatchQueue(label: "elevator.state")
    ) {
        self.minFloor = minFloor
        self.maxFloor = maxFloor
        self.queue = queue
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
        // TODO: Increment it sloooowly, checking for power, to animate movement :)
        self._currentFloor = Double(floor)

        self._floorsPressedInCabin.remove(floor)
        self._floorsCalled.remove(floor)

        if self._floorsCalled.isEmpty && self._floorsPressedInCabin.isEmpty {
            self._direction = nil
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
        queue.sync {
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
        queue.async { [weak self] in
            guard let self else { return }
            self._floorsPressedInCabin.insert(floor)
            self._move()
        }
    }
}

extension ElevatorState: FloorControl {
    var closestFloor: Int {
        queue.sync {
            Int(round(_currentFloor))
        }
    }

    var direction: Direction? {
        queue.sync {
            _direction
        }
    }

    func callOnFloor(_ floor: Int) {
        queue.async { [weak self] in
            guard let self else { return }
            self._floorsCalled.insert(floor)
            self._move()
        }
    }
}

extension ElevatorState: DispatcherControl {
    var currentFloor: Double {
        queue.sync {
            _currentFloor
        }
    }

    var isPowerOn: Bool {
        queue.sync {
            _isPowerOn
        }
    }

    func togglePower() {
        queue.async { [weak self] in
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

extension ElevatorState: Floors {
    var floorsCalledStates: [ButtonState] {
        queue.sync {
            Array(minFloor...maxFloor)
                .reversed()
                .map { floor in
                    let isPressed = self._floorsCalled.contains(floor)
                    return ButtonState(floor: floor, isPressed: isPressed)
                }
        }
    }
}
