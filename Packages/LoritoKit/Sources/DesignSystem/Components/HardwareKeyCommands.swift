import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A hardware-keyboard command that must win over the system focus behavior
/// (Return, Escape): SwiftUI's `keyboardShortcut` can't set
/// `wantsPriorityOverSystemBehavior`, so these go through a UIKit responder.
/// Listed in the ⌘ overlay under its title.
public struct HardwareKeyCommand {
    public enum Key { case `return`, escape }

    public let key: Key
    public let title: String
    public let action: () -> Void

    public init(_ key: Key, title: String, action: @escaping () -> Void) {
        self.key = key
        self.title = title
        self.action = action
    }
}

public extension View {
    /// Register priority key commands while this view is on screen. Pass an
    /// empty array when the matching on-screen action is hidden or disabled.
    func hardwareKeyCommands(_ commands: [HardwareKeyCommand]) -> some View {
        #if os(iOS)
        background(KeyCommandResponder(commands: commands).frame(width: 0, height: 0).accessibilityHidden(true))
        #else
        self
        #endif
    }
}

#if os(iOS)
private struct KeyCommandResponder: UIViewRepresentable {
    let commands: [HardwareKeyCommand]

    func makeUIView(context: Context) -> ResponderView { ResponderView() }

    func updateUIView(_ view: ResponderView, context: Context) {
        view.commands = commands
        view.claimFirstResponder()
    }

    final class ResponderView: UIView {
        var commands: [HardwareKeyCommand] = []

        override var canBecomeFirstResponder: Bool { true }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            claimFirstResponder()
        }

        func claimFirstResponder() {
            guard window != nil, !isFirstResponder else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self, self.window != nil else { return }
                self.becomeFirstResponder()
            }
        }

        override var keyCommands: [UIKeyCommand]? {
            commands.enumerated().map { index, command in
                let input = command.key == .return ? "\r" : UIKeyCommand.inputEscape
                let keyCommand = UIKeyCommand(title: command.title, action: #selector(runCommand(_:)),
                                              input: input, modifierFlags: [], propertyList: index)
                keyCommand.discoverabilityTitle = command.title
                keyCommand.wantsPriorityOverSystemBehavior = true
                return keyCommand
            }
        }

        @objc private func runCommand(_ sender: UIKeyCommand) {
            guard let index = sender.propertyList as? Int, commands.indices.contains(index) else { return }
            commands[index].action()
        }
    }
}
#endif
