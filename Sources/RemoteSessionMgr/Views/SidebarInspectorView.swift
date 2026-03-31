import SwiftUI

struct SidebarInspectorView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ScrollView {
            Group {
                if viewModel.selectedSession != nil {
                    sessionInspector
                } else if viewModel.selectedFolder != nil {
                    folderInspector
                } else {
                    emptyInspector
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var sessionInspector: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connection")
                .font(.headline)

            inspectorField("Name") {
                TextField("Session name", text: viewModel.bindingForSelectedSession(\.name, default: ""))
                    .textFieldStyle(.roundedBorder)
            }

            inspectorField("Protocol") {
                Picker(
                    "Protocol",
                    selection: Binding(
                        get: { viewModel.selectedSession?.protocolType ?? .ssh },
                        set: { viewModel.updateProtocol($0) }
                    )
                ) {
                    ForEach(SessionProtocol.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            inspectorField("Host") {
                TextField("Hostname or IP", text: viewModel.bindingForSelectedSession(\.host, default: ""))
                    .textFieldStyle(.roundedBorder)
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Port")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("22", text: portBinding)
                        .textFieldStyle(.roundedBorder)
                }
                .frame(width: 76)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Username")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Username", text: viewModel.bindingForSelectedSession(\.username, default: ""))
                        .textFieldStyle(.roundedBorder)
                }
            }

            inspectorField("Password") {
                SecureField("Password", text: viewModel.bindingForSelectedSession(\.password, default: ""))
                    .textFieldStyle(.roundedBorder)
            }

            Button("Connect") {
                viewModel.connectSelectedSession()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedSession == nil)

            Divider()

            inspectorField("Notes") {
                TextEditor(text: viewModel.bindingForSelectedSession(\.notes, default: ""))
                    .frame(minHeight: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.15))
                    )
            }

            Spacer(minLength: 0)
        }
    }

    private var folderInspector: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Folder")
                .font(.headline)
            inspectorField("Name") {
                TextField("Folder name", text: viewModel.bindingForSelectedFolderName())
                    .textFieldStyle(.roundedBorder)
            }
            Spacer(minLength: 0)
        }
    }

    private var emptyInspector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No Selection")
                .font(.headline)
            Text("Select a session or folder to edit it here.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func inspectorField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private var portBinding: Binding<String> {
        Binding(
            get: {
                guard let session = viewModel.selectedSession else { return "" }
                return String(session.port)
            },
            set: { newValue in
                let filtered = newValue.filter(\.isNumber)
                if let port = Int(filtered), port > 0 {
                    viewModel.bindingForSelectedSession(\.port, default: 22).wrappedValue = port
                }
            }
        )
    }
}
