import AppKit
import SwiftUI
import AirDialCore

final class AppModel: ObservableObject {
    let preferences = Preferences()
    @Published var language: AppLanguage
    @Published var enabled = false
    @Published var status: TextKey = .inactive
    @Published var lastAction: GestureAction?
    @Published var volume: Double?
    @Published var progress = 0.0
    @Published var direction = 0
    @Published var notice: TextKey?
    @Published var enableOnLaunch: Bool
    var refreshMenu: (() -> Void)?
    private let camera = CameraService()
    private let audio = SystemVolume()
    private let media = MediaControl()
    private var wantsControl = false
    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    private var sleeping = false

    init() {
        language = preferences.language
        enableOnLaunch = preferences.enableOnLaunch
        volume = audio.read()
        camera.onState = { [weak self] state in self?.cameraChanged(state) }
        camera.onGesture = { [weak self] result in self?.handle(result) }
        camera.onVisionError = { [weak self] in self?.notice = .visionFailed }
        let center = NSWorkspace.shared.notificationCenter
        sleepObserver = center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            self.sleeping = true; self.enabled = false; self.camera.stop(); self.refreshMenu?()
        }
        wakeObserver = center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            self.sleeping = false
            if self.wantsControl { self.status = .starting; self.camera.start() }
        }
    }

    deinit {
        if let sleepObserver { NSWorkspace.shared.notificationCenter.removeObserver(sleepObserver) }
        if let wakeObserver { NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver) }
    }

    func text(_ key: TextKey) -> String { localized(key, language) }
    func launch() { if enableOnLaunch { setControl(true) } }
    func refreshVolume() { volume = audio.read() }

    func setLanguage(_ value: AppLanguage) {
        language = value; preferences.language = value; refreshMenu?()
    }

    func toggleLaunch() {
        enableOnLaunch.toggle(); preferences.enableOnLaunch = enableOnLaunch
        // Switching to manual mode stops immediately; switching back starts immediately.
        setControl(enableOnLaunch)
    }

    func toggleControl() { setControl(!wantsControl) }
    var controlRequested: Bool { wantsControl }

    private func setControl(_ on: Bool) {
        wantsControl = on; notice = nil; progress = 0; direction = 0
        if on, !sleeping {
            status = .starting; camera.start()
        } else {
            enabled = false; status = .inactive; camera.stop()
        }
        refreshMenu?()
    }

    func quit() { wantsControl = false; enabled = false; camera.shutdown() }

    private func cameraChanged(_ state: CameraService.State) {
        guard wantsControl, !sleeping else { enabled = false; status = .inactive; refreshMenu?(); return }
        switch state {
        case .running: enabled = true; status = .active
        case .stopped: return // A newer start may already be queued.
        case .denied:
            enabled = false; wantsControl = false; status = .cameraDenied
            let alert = NSAlert()
            alert.messageText = text(.permissionTitle); alert.informativeText = text(.permissionBody)
            alert.addButton(withTitle: text(.settings)); alert.addButton(withTitle: text(.done))
            NSApp.activate(ignoringOtherApps: true)
            if alert.runModal() == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
                    NSWorkspace.shared.open(url)
                }
            }
        case .missing: enabled = false; wantsControl = false; status = .cameraMissing
        case .failed: enabled = false; wantsControl = false; status = .cameraFailed
        }
        refreshMenu?()
    }

    private func handle(_ result: GestureResult) {
        guard enabled, wantsControl, !sleeping else { return }
        progress = result.circleProgress; direction = result.direction
        for action in result.actions {
            if action == .volumeUp || action == .volumeDown {
                if let value = audio.change(by: action == .volumeUp ? 0.05 : -0.05) {
                    volume = value; notice = nil; lastAction = action
                } else { notice = .volumeUnavailable }
            } else {
                if media.send(action) { lastAction = action; notice = nil }
                else { notice = .mediaUnavailable }
            }
        }
        if !result.actions.isEmpty { refreshMenu?() }
    }
}
