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

protocol CabinControl: Observable {
    var floorButtonPressedStates: [Bool] { get }
    var floorButtonsEnabled: Bool { get }

    func pressFloorInCabin(_ floor: Int)
}

protocol FloorControl: Observable {
    var closestFloor: Int { get }
    var direction: Direction? { get }

    func callOnFloor(_ floor: Int)
}

protocol DispatcherControl: Observable {
    var closestFloor: Int { get }
    var direction: Direction? { get }

    func togglePower()
}

@Observable
class ElevatorState {
    let minFloor: Int
    let maxFloor: Int

    var isPowerOn: Bool {
        queue.sync {
            _isPowerOn
        }
    }

    var currentFloor: Double {
        queue.sync {
            _currentFloor
        }
    }

    var floorsPressedInCabin: Set<Int> {
        queue.sync {
            _floorsPressedInCabin
        }
    }

    var floorsCalled: Set<Int> {
        queue.sync {
            _floorsCalled
        }
    }

    private var _direction: Direction?
    private var _isPowerOn = true
    private var _currentFloor = 1.0

    private let queue: DispatchQueue

    var _floorsPressedInCabin: Set<Int> = []
    var _floorsCalled: Set<Int> = []

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
            // TODO: looks like we need to check that max is actually still down
            if let floor = [nearestPressedFloor, nearestCalledFloor].compactMap(
                \.self
            ).max() {
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

    private func _nearestPressedFloor(from currentFloor: Double) -> Int? {
        return _nearestFloor(from: currentFloor, in: _floorsPressedInCabin)
    }

    private func _nearestCalledFloor(from currentFloor: Double) -> Int? {
        return _nearestFloor(from: currentFloor, in: _floorsCalled)
    }

    private func _nearestFloor(from currentFloor: Double, in floors: Set<Int>) -> Int? {
        floors.compactMap(\.self).min(by: {
            abs(Double($0) - currentFloor) < abs(Double($1) - currentFloor)
        })
    }

    private func _direction(from fromFloor: Double, to toFloor: Int)
        -> Direction
    {
        return fromFloor < Double(toFloor) ? .up : .down
    }
}

extension ElevatorState: CabinControl {
    var floorButtonPressedStates: [Bool] {
        queue.sync {
            [minFloor...maxFloor]
                .map { self._floorsPressedInCabin.contains($0) }
        }
    }

    var floorButtonsEnabled: Bool {
        isPowerOn
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
