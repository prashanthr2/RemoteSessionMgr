import SwiftUI

struct SSHTabBarView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                detailsTab

                ForEach(viewModel.sshTabs) { tab in
                    sessionTab(for: tab)
                }
            }
            .padding(.horizontal, 10)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var detailsTab: some View {
        attachedTab(
            isSelected: isDetailsSelected,
            onSelect: { viewModel.showDetailsPane() }
        ) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Details")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(detailsSubtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func sessionTab(for tab: EmbeddedSSHSession) -> some View {
        attachedTab(
            isSelected: isSelected(tab.id),
            onSelect: { viewModel.selectSSHTab(tab.id) }
        ) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(tab.state.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Button {
                    viewModel.closeSSHTab(tab.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .padding(4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func attachedTab<Content: View>(
        isSelected: Bool,
        onSelect: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                HStack {
                    content()
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 9)
                .frame(minWidth: 118, alignment: .leading)

                Rectangle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(height: 2)
            }
            .background(isSelected ? Color.primary.opacity(0.05) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    private var isDetailsSelected: Bool {
        if case .details = viewModel.activeDetailPane { return true }
        return false
    }

    private func isSelected(_ tabID: UUID) -> Bool {
        if case .ssh(let activeID) = viewModel.activeDetailPane {
            return activeID == tabID
        }
        return false
    }

    private var detailsSubtitle: String {
        if let session = viewModel.selectedSession {
            return session.protocolType.rawValue
        }
        if viewModel.selectedFolder != nil {
            return "Folder"
        }
        return "Selection"
    }
}
