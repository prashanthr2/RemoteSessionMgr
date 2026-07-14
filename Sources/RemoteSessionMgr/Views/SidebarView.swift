import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            // ── Action bar ────────────────────────────────────────────────
            actionBar

            Divider()

            // ── Search field ──────────────────────────────────────────────
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
                TextField("Search sessions", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // ── Session list + inspector ───────────────────────────────────
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

                SidebarInspectorView()
                    .frame(minHeight: 260, idealHeight: 320)
            }
        }
        .frame(minWidth: 300, idealWidth: 340)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { installDeleteKeyMonitor() }
    }

    // MARK: – Action bar

    private var actionBar: some View {
        HStack(spacing: 0) {
            actionButton("plus.rectangle.on.rectangle", help: "New Session") {
                viewModel.newSession()
            }
            actionButton("folder.badge.plus", help: "New Folder") {
                viewModel.newFolder()
            }
            actionButton("square.and.arrow.down", help: "Import mRemoteNG XML") {
                openImportPanel()
            }

            Spacer()

            actionButton(
                "trash",
                help: "Delete Selected",
                color: viewModel.selection == nil ? Color.secondary : Color.red,
                disabled: viewModel.selection == nil
            ) {
                viewModel.deleteSelectedItem()
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func actionButton(
        _ icon: String,
        help: String,
        color: Color = .primary,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 30, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .help(help)
    }

    // MARK: – Helpers

    private func openImportPanel() {
        let panel = NSOpenPanel()
        panel.title = "Import mRemoteNG Connections"
        panel.message = "Select your mRemoteNG confCons.xml file"
        panel.allowedContentTypes = [.xml]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            viewModel.importMRemoteNG(from: url)
        }
    }

    private func installDeleteKeyMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard (event.keyCode == 51 || event.keyCode == 117),
                  event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty,
                  viewModel.selection != nil else { return event }
            let responder = NSApp.keyWindow?.firstResponder
            let isTextInput = responder is NSTextView || responder is NSTextField
            guard !isTextInput else { return event }
            viewModel.deleteSelectedItem()
            return nil
        }
    }

    private var selectionBinding: Binding<SidebarSelection?> {
        Binding(
            get: { viewModel.selection },
            set: { viewModel.handleSelectionChange($0) }
        )
    }

    // MARK: – Row builder

    @ViewBuilder
    private func sidebarRow(for node: SidebarNode) -> some View {
        switch node.kind {
        case .folder:
            Label(node.title, systemImage: "folder")
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .contextMenu {
                    Button("New Session in Folder") {
                        viewModel.handleSelectionChange(node.id)
                        viewModel.newSession()
                    }
                    Button("New Subfolder") {
                        viewModel.handleSelectionChange(node.id)
                        viewModel.newFolder()
                    }
                    Divider()
                    Button("Delete Folder", role: .destructive) {
                        viewModel.handleSelectionChange(node.id)
                        viewModel.deleteSelectedItem()
                    }
                }

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
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture(count: 2).onEnded {
                    if case .session(let sessionID) = node.id {
                        viewModel.connectSession(withID: sessionID)
                    }
                }
            )
            .contextMenu {
                Button("Connect") {
                    if case .session(let sessionID) = node.id {
                        viewModel.connectSession(withID: sessionID)
                    }
                }
                Divider()
                Button("Delete Session", role: .destructive) {
                    viewModel.handleSelectionChange(node.id)
                    viewModel.deleteSelectedItem()
                }
            }
        }
    }
}
