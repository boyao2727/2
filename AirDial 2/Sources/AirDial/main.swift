import AppKit
import SwiftUI
import AirDialCore

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let model = AppModel()
    private var statusItem: NSStatusItem!
    private var guide: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        model.refreshMenu = { [weak self] in self?.updateIcon() }
        updateIcon()
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        if CommandLine.arguments.contains("--preview-guide") {
            showGuide()
        } else {
            model.launch()
        }
    }

    private func updateIcon() {
        let name = model.enabled ? "hand.point.up.left.fill" : "hand.point.up.left"
        let icon = NSImage(systemSymbolName: name, accessibilityDescription: "AirDial")
        icon?.isTemplate = true
        statusItem?.button?.image = icon
        statusItem?.button?.toolTip = "AirDial · " + model.text(model.status)
        if let guide { guide.title = model.text(.guide) + " — AirDial" }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        model.refreshVolume()
        menu.removeAllItems()
        let automatic = item(model.text(.launch), #selector(toggleLaunch))
        let launchLabel = NSTextField(labelWithString: model.text(.launch))
        launchLabel.font = .menuFont(ofSize: 0)
        let launchSwitch = NSSwitch()
        launchSwitch.state = model.enableOnLaunch ? .on : .off
        launchSwitch.target = self
        launchSwitch.action = #selector(toggleLaunch)
        launchSwitch.setAccessibilityLabel(model.text(.launch))
        let launchRow = NSStackView(views: [launchLabel, launchSwitch])
        launchRow.orientation = .horizontal
        launchRow.alignment = .centerY
        launchRow.distribution = .fill
        launchRow.spacing = 12
        launchRow.edgeInsets = .init(top: 4, left: 14, bottom: 4, right: 14)
        launchRow.frame = .init(x: 0, y: 0, width: 260, height: 32)
        automatic.view = launchRow
        menu.addItem(automatic)
        if !model.enableOnLaunch {
            menu.addItem(item(model.text(model.controlRequested ? .disable : .enable), #selector(toggleControl)))
        }
        menu.addItem(item(model.text(.guide), #selector(showGuide)))
        let languageItem = NSMenuItem(title: model.text(.language), action: nil, keyEquivalent: "")
        let languages = NSMenu()
        let chinese = item("简体中文", #selector(chineseLanguage))
        let english = item("English (US)", #selector(englishLanguage))
        chinese.state = model.language == .chinese ? .on : .off
        english.state = model.language == .english ? .on : .off
        languages.addItem(chinese); languages.addItem(english)
        languageItem.submenu = languages; menu.addItem(languageItem)
        menu.addItem(.separator())
        let quit = item(model.text(.quit), #selector(quitApplication))
        quit.keyEquivalent = "q"; menu.addItem(quit)
    }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self; return item
    }

    @objc private func toggleLaunch() {
        model.toggleLaunch()
        statusItem.menu?.cancelTracking()
    }
    @objc private func toggleControl() { model.toggleControl() }
    @objc private func chineseLanguage() { model.setLanguage(.chinese) }
    @objc private func englishLanguage() { model.setLanguage(.english) }
    @objc private func quitApplication() { NSApp.terminate(nil) }

    @objc private func showGuide() {
        model.refreshVolume()
        if guide == nil {
            let window = NSWindow(contentRect: .init(x: 0, y: 0, width: 660, height: 740),
                styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
            window.contentView = NSHostingView(rootView: GuideView(model: model))
            window.isReleasedWhenClosed = false
            window.center(); guide = window
        }
        guide?.title = model.text(.guide) + " — AirDial"
        guide?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) { model.quit() }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

// Hardware-free installation diagnostic. Never requests camera access or sends media commands.
if CommandLine.arguments.contains("--self-check") {
    print("AirDial 0.1.0-beta")
    print("Media command bridge: \(MediaControl().available ? "available" : "unavailable")")
    print("System volume control: \(SystemVolume().read() != nil ? "available" : "unavailable")")
    print("Camera, microphone, Photos, personal files, network: not accessed")
} else {
    let application = NSApplication.shared
    let delegate = AppDelegate()
    application.delegate = delegate
    application.run()
    withExtendedLifetime(delegate) {}
}
