import AppKit

// MARK: - Global Hotkey Manager

final class GlobalHotkeyManager {
    static let shared = GlobalHotkeyManager()
    private var eventMonitor: Any?

    func register(onTrigger: @escaping () -> Void) {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.option) && event.keyCode == 49 {
                DispatchQueue.main.async {
                    onTrigger()
                }
            }
        }
    }

    func unregister() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

