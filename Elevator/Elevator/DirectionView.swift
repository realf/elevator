//
//  DirectionView.swift
//  Elevator
//
//  Created by alf on 05.12.2025.
//

import SwiftUI

struct DirectionView: View {
    let direction: Direction?

    var body: some View {
        let colors: (up: Color, down: Color) = switch direction {
        case .up: (.orange, .gray)
        case .down: (.gray, .orange)
        case nil: (.gray, .gray)
        }

        VStack {
            Image(systemName: "arrowtriangle.up.fill")
                .foregroundStyle(colors.up)
            Image(systemName: "arrowtriangle.down.fill")
                .foregroundStyle(colors.down)
        }
    }
}

#Preview {
    DirectionView(direction: .up)
}

#Preview {
    DirectionView(direction: .down)
}

#Preview {
    DirectionView(direction: nil)
}
