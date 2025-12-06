//
//  RoundButton.swift
//  Elevator
//
//  Created by alf on 05.12.2025.
//

import SwiftUI

struct RoundButton: ViewModifier {
    @Environment(\.isEnabled) var isEnabled

    let buttonSize = 44.0
    let foregroundColor: Color
    let backgroundColor: Color

    func body(content: Content) -> some View {
        content
            .frame(width: buttonSize, height: buttonSize)
            .foregroundStyle(foregroundColor)
            .background(
                isEnabled ? backgroundColor : backgroundColor.opacity(0.7)
            )
            .clipShape(Circle())
    }
}

extension View {
    func roundButton(foregroundColor: Color = .white, backgroundColor: Color)
        -> some View
    {
        modifier(
            RoundButton(
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor
            )
        )
    }
}
