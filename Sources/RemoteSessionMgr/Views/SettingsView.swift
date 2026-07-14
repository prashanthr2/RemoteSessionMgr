import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        Form {
            Picker("Default SSH launcher", selection: $viewModel.settings.defaultSSHLauncher) {
                ForEach(SSHLauncherOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }

            TextField("RDP command template", text: $viewModel.settings.rdpCommandTemplate)
                .textFieldStyle(.roundedBorder)

            Text("Supported placeholders: {host}, {port}, {username}, {password}, {name}")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Default uses sdl-freerdp (install with `brew install freerdp`), which opens a native window and needs no XQuartz.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onChange(of: viewModel.settings.defaultSSHLauncher) { _ in
            viewModel.saveSettings()
        }
        .onChange(of: viewModel.settings.rdpCommandTemplate) { _ in
            viewModel.saveSettings()
        }
    }
}
