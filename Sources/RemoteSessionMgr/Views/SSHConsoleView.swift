import SwiftUI

struct SSHConsoleView: View {
    @ObservedObject var tab: EmbeddedSSHSession

    var body: some View {
        SwiftTermContainerView(tab: tab)
            .id(tab.id)
            .background(Color.black)
    }
}
