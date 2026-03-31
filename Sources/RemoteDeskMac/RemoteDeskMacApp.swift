import SwiftUI

@main
struct RemoteDeskMacApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        .defaultSize(width: 1200, height: 760)

        Settings {
            SettingsView()
                .environmentObject(viewModel)
                .frame(width: 520, height: 280)
                .padding(20)
        }
    }
}
