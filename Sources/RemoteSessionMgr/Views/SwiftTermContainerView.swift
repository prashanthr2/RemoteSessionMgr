import AppKit
import SwiftTerm
import SwiftUI

struct SwiftTermContainerView: NSViewRepresentable {
    @ObservedObject var tab: EmbeddedSSHSession

    func makeNSView(context: Context) -> TerminalHostContainerView {
        let container = TerminalHostContainerView()
        container.attach(tab.terminalView)
        return container
    }

    func updateNSView(_ nsView: TerminalHostContainerView, context: Context) {
        nsView.attach(tab.terminalView)

        if tab.shouldFocusTerminal {
            DispatchQueue.main.async {
                tab.terminalView.window?.makeFirstResponder(tab.terminalView)
                tab.shouldFocusTerminal = false
            }
        }
    }
}

final class TerminalHostContainerView: NSView {
    func attach(_ terminalView: NSView) {
        for subview in subviews where subview !== terminalView {
            subview.removeFromSuperview()
        }

        if terminalView.superview !== self {
            terminalView.removeFromSuperview()
            addSubview(terminalView)
        }

        terminalView.frame = bounds
        terminalView.autoresizingMask = [.width, .height]
        needsLayout = true
    }

    override func layout() {
        super.layout()
        subviews.first?.frame = bounds
    }

    // Clicking anywhere in the container focuses the terminal
    override func mouseDown(with event: NSEvent) {
        if let terminal = subviews.first {
            window?.makeFirstResponder(terminal)
        }
        super.mouseDown(with: event)
    }

    // When added to a window, request focus immediately
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil, let terminal = subviews.first else { return }
        DispatchQueue.main.async { [weak self] in
            self?.window?.makeFirstResponder(terminal)
        }
    }
}
