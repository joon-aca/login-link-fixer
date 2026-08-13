import AppKit

@MainActor
final class AboutWindowController: NSWindowController {
    private let repositoryURL = URL(string: "https://github.com/joon-aca/login-link-fixer")!

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 430, height: 450),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "About Login Link Fixer"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        window.backgroundColor = .windowBackgroundColor

        super.init(window: window)
        buildUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func present() {
        guard let window else { return }
        window.center()
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func buildUI() {
        guard let contentView = window?.contentView else { return }

        let iconView = NSImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = NSApp.applicationIconImage
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.setAccessibilityLabel("Login Link Fixer icon")

        let titleLabel = label("Login Link Fixer", size: 25, weight: .semibold, color: .labelColor)
        let versionLabel = label(versionText, size: 12, weight: .regular, color: .secondaryLabelColor)

        let descriptionLabel = label(
            "Repairs login links mangled by line breaks or Markdown, then opens them in your default browser.",
            size: 14,
            weight: .regular,
            color: .labelColor
        )
        descriptionLabel.alignment = .center
        descriptionLabel.maximumNumberOfLines = 3

        let shortcutLabel = label("Quick Fix  ⌥⌘L", size: 13, weight: .medium, color: .labelColor)
        shortcutLabel.alignment = .center
        shortcutLabel.wantsLayer = true
        shortcutLabel.layer?.cornerRadius = 8
        shortcutLabel.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        let privacyLabel = label(
            "Private by design · No backend · No analytics · Nothing stored",
            size: 11,
            weight: .regular,
            color: .secondaryLabelColor
        )
        privacyLabel.alignment = .center
        privacyLabel.maximumNumberOfLines = 2

        let repositoryButton = NSButton(title: "View source on GitHub  ↗", target: self, action: #selector(openRepository))
        repositoryButton.translatesAutoresizingMaskIntoConstraints = false
        repositoryButton.bezelStyle = .rounded
        repositoryButton.controlSize = .large

        let copyrightLabel = label("© 2026 Joon Lee", size: 10, weight: .regular, color: .tertiaryLabelColor)
        copyrightLabel.alignment = .center

        let stack = NSStackView(views: [
            iconView,
            titleLabel,
            versionLabel,
            descriptionLabel,
            shortcutLabel,
            privacyLabel,
            repositoryButton,
            copyrightLabel,
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 9
        stack.setCustomSpacing(2, after: titleLabel)
        stack.setCustomSpacing(18, after: versionLabel)
        stack.setCustomSpacing(17, after: descriptionLabel)
        stack.setCustomSpacing(16, after: shortcutLabel)
        stack.setCustomSpacing(18, after: privacyLabel)
        stack.setCustomSpacing(18, after: repositoryButton)
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 112),
            iconView.heightAnchor.constraint(equalToConstant: 112),
            descriptionLabel.widthAnchor.constraint(equalToConstant: 340),
            shortcutLabel.widthAnchor.constraint(equalToConstant: 150),
            shortcutLabel.heightAnchor.constraint(equalToConstant: 34),
            privacyLabel.widthAnchor.constraint(equalToConstant: 340),
            repositoryButton.widthAnchor.constraint(equalToConstant: 190),
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 42),
        ])
    }

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    private func label(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSTextField {
        let field = NSTextField(wrappingLabelWithString: text)
        field.translatesAutoresizingMaskIntoConstraints = false
        field.font = .systemFont(ofSize: size, weight: weight)
        field.textColor = color
        return field
    }

    @objc private func openRepository() {
        NSWorkspace.shared.open(repositoryURL)
    }
}
