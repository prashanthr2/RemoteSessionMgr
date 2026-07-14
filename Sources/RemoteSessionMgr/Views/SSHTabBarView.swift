import SwiftUI

struct SSHTabBarView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                detailsTab

                // Vertical separator between Details and SSH tabs
                if !viewModel.sshTabs.isEmpty {
                    Divider()
                        .frame(height: 28)
                        .padding(.horizontal, 2)
                }

                ForEach(viewModel.sshTabs) { tab in
                    sessionTab(for: tab)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .frame(height: 52)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var detailsTab: some View {
        tabButton(
            isSelected: isDetailsSelected,
            onSelect: { viewModel.showDetailsPane() }
        ) {
            Label {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Details")
                        .font(.system(size: 12, weight: .medium))
                    Text(detailsSubtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "sidebar.right")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func sessionTab(for tab: EmbeddedSSHSession) -> some View {
        tabButton(
            isSelected: isSelected(tab.id),
            onSelect: { viewModel.selectSSHTab(tab.id) }
        ) {
            HStack(spacing: 6) {
                Image(systemName: "terminal")
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected(tab.id) ? Color.accentColor : .secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text(tab.title)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                    Text(tab.state.label)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                Button {
                    viewModel.closeSSHTab(tab.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(3)
                        .background(Color.primary.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func tabButton<Content: View>(
        isSelected: Bool,
        onSelect: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button(action: onSelect) {
            content()
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(minWidth: 110, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isSelected
                              ? Color(NSColor.selectedControlColor).opacity(0.45)
                              : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(
                            isSelected ? Color.accentColor.opacity(0.4) : Color.clear,
                            lineWidth: 1
                        )
                )
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
