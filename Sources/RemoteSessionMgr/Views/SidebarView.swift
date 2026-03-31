import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        VSplitView {
            List(selection: selectionBinding) {
                ForEach(viewModel.sidebarNodes) { node in
                    OutlineGroup([node], children: \.children) { item in
                        sidebarRow(for: item)
                            .tag(item.id)
                    }
                }
            }
            .listStyle(.sidebar)
            .searchable(text: $viewModel.searchText, placement: .sidebar, prompt: "Search sessions")

            SidebarInspectorView()
                .frame(minHeight: 260, idealHeight: 320)
        }
        .frame(minWidth: 300, idealWidth: 340)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var selectionBinding: Binding<SidebarSelection?> {
        Binding(
            get: { viewModel.selection },
            set: { viewModel.handleSelectionChange($0) }
        )
    }

    @ViewBuilder
    private func sidebarRow(for node: SidebarNode) -> some View {
        switch node.kind {
        case .folder:
            Label(node.title, systemImage: "folder")
                .font(.body)
        case .session:
            VStack(alignment: .leading, spacing: 2) {
                Label(node.title, systemImage: "desktopcomputer")
                if let subtitle = node.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.handleSelectionChange(node.id)
            }
            .onTapGesture(count: 2) {
                if case .session(let sessionID) = node.id {
                    viewModel.connectSession(withID: sessionID)
                }
            }
        }
    }
}
