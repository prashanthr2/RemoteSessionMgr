import SwiftUI

struct SessionEditorView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let sessionID: UUID

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                form
                footer
            }
            .padding(24)
            .frame(maxWidth: 760, alignment: .leading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Session Details")
                .font(.largeTitle)
                .fontWeight(.semibold)
            Text("Configure connection details for SSH or RDP.")
                .foregroundStyle(.secondary)
        }
    }

    private var form: some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 14) {
            labeledField("Name") {
                TextField("Session name", text: viewModel.bindingForSelectedSession(\.name, default: ""))
            }

            labeledField("Protocol") {
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
                .pickerStyle(.segmented)
                .frame(maxWidth: 240)
            }

            labeledField("Host") {
                TextField("example.internal", text: viewModel.bindingForSelectedSession(\.host, default: ""))
                    .textFieldStyle(.roundedBorder)
            }

            labeledField("Port") {
                TextField("Port", text: portBinding)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 120)
            }

            labeledField("Username") {
                TextField("Username", text: viewModel.bindingForSelectedSession(\.username, default: ""))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)
            }

            labeledField("Password") {
                SecureField("Password", text: viewModel.bindingForSelectedSession(\.password, default: ""))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)
            }

            labeledField("Notes") {
                TextEditor(text: viewModel.bindingForSelectedSession(\.notes, default: ""))
                    .font(.body)
                    .frame(minHeight: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.15))
                    )
            }
        }
    }

    private var footer: some View {
        HStack {
            if let session = viewModel.selectedSession, session.id == sessionID {
                Text("Created \(session.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .foregroundStyle(.secondary)
                Text("Updated \(session.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Delete", role: .destructive) {
                viewModel.deleteSelectedItem()
            }

            Button("Connect") {
                viewModel.connectSelectedSession()
            }
            .keyboardShortcut(.defaultAction)
        }
    }

    private var portBinding: Binding<String> {
        Binding(
            get: {
                guard let session = viewModel.selectedSession, session.id == sessionID else { return "" }
                return String(session.port)
            },
            set: { newValue in
                let filtered = newValue.filter(\.isNumber)
                if let port = Int(filtered), port > 0 {
                    viewModel.bindingForSelectedSession(\.port, default: 0).wrappedValue = port
                }
            }
        )
    }

    @ViewBuilder
    private func labeledField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        GridRow {
            Text(title)
                .fontWeight(.medium)
                .frame(width: 110, alignment: .leading)
            content()
        }
    }
}
