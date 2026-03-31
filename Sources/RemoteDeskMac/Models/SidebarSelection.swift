import Foundation

enum SidebarSelection: Hashable {
    case folder(UUID)
    case session(UUID)
}

struct SidebarNode: Identifiable, Hashable {
    enum Kind: Hashable {
        case folder
        case session
    }

    let id: SidebarSelection
    let title: String
    let subtitle: String?
    let kind: Kind
    let children: [SidebarNode]?
}

enum DetailPane: Hashable {
    case details
    case ssh(UUID)
}
