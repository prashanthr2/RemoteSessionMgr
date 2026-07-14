import SwiftUI

struct SSHConsoleView: View {
    @ObservedObject var tab: EmbeddedSSHSession

    var body: some View {
        SwiftTermContainerView(tab: tab)
            .id(tab.id)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
    }
}
