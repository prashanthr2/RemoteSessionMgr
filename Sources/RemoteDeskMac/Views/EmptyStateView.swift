import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.3.group.bubble.left")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Select a session or folder")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Use the toolbar to create your first SSH or RDP session.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
