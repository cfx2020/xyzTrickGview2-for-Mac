import Cocoa
import Carbon.HIToolbox

// Callback for hotkey events
typealias HotkeyCallback = (HotkeyType) -> Void

final class HotkeyService {
    private struct HotkeyRegistration {
        let id: UInt32
        let eventHotKeyID: EventHotKeyID
        var hotKeyRef: EventHotKeyRef?
    }

    private let callback: HotkeyCallback
    private var eventHandler: EventHandlerRef?
    private var registrations: [HotkeyRegistration] = []

    private let signature: OSType = 0x58594D54 // 'XYMT'
    private let xyzHotkeyID: UInt32 = 1
    private let gviewHotkeyID: UInt32 = 2

    init(callback: @escaping HotkeyCallback) {
        self.callback = callback
    }

    deinit {
        unregisterHotkeys()
    }

    func registerHotkeys(
        xyzShortcut: String = "⌘⌥X",
        gviewShortcut: String = "⌘⌥G"
    ) {
        unregisterHotkeys()

        installEventHandlerIfNeeded()

        let xyzParsed = parseShortcut(xyzShortcut) ?? (UInt32(kVK_ANSI_X), UInt32(cmdKey | optionKey))
        let gviewParsed = parseShortcut(gviewShortcut) ?? (UInt32(kVK_ANSI_G), UInt32(cmdKey | optionKey))

        let success1 = registerHotkey(id: xyzHotkeyID, keyCode: xyzParsed.keyCode, modifiers: xyzParsed.modifiers)
        let success2 = registerHotkey(id: gviewHotkeyID, keyCode: gviewParsed.keyCode, modifiers: gviewParsed.modifiers)

        if success1 && success2 {
            Logger.shared.info("Global hotkeys registered: cmd+opt+x / cmd+opt+g")
        } else {
            Logger.shared.warning("One or more global hotkeys failed to register")
        }
    }

    func unregisterHotkeys() {
        for registration in registrations {
            if let hotKeyRef = registration.hotKeyRef {
                UnregisterEventHotKey(hotKeyRef)
            }
        }
        registrations.removeAll()

        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }

        Logger.shared.info("Global hotkeys unregistered")
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandler == nil else { return }

        var eventTypes = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let userData = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            HotkeyService.hotkeyEventHandler,
            1,
            &eventTypes,
            userData,
            &eventHandler
        )

        if status != noErr {
            Logger.shared.error("Failed to install hotkey event handler: \(status)")
        }
    }

    private func registerHotkey(id: UInt32, keyCode: UInt32, modifiers: UInt32) -> Bool {
        let eventHotKeyID = EventHotKeyID(signature: signature, id: id)
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            eventHotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr {
            registrations.append(HotkeyRegistration(id: id, eventHotKeyID: eventHotKeyID, hotKeyRef: hotKeyRef))
            return true
        }

        Logger.shared.error("Failed to register hotkey id=\(id), keyCode=\(keyCode), modifiers=\(modifiers), status=\(status)")
        return false
    }

    private func parseShortcut(_ raw: String) -> (keyCode: UInt32, modifiers: UInt32)? {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: "CMD", with: "⌘")
            .replacingOccurrences(of: "ALT", with: "⌥")
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: " ", with: "")

        let map: [Character: UInt32] = [
            "A": UInt32(kVK_ANSI_A), "B": UInt32(kVK_ANSI_B), "C": UInt32(kVK_ANSI_C),
            "D": UInt32(kVK_ANSI_D), "E": UInt32(kVK_ANSI_E), "F": UInt32(kVK_ANSI_F),
            "G": UInt32(kVK_ANSI_G), "H": UInt32(kVK_ANSI_H), "I": UInt32(kVK_ANSI_I),
            "J": UInt32(kVK_ANSI_J), "K": UInt32(kVK_ANSI_K), "L": UInt32(kVK_ANSI_L),
            "M": UInt32(kVK_ANSI_M), "N": UInt32(kVK_ANSI_N), "O": UInt32(kVK_ANSI_O),
            "P": UInt32(kVK_ANSI_P), "Q": UInt32(kVK_ANSI_Q), "R": UInt32(kVK_ANSI_R),
            "S": UInt32(kVK_ANSI_S), "T": UInt32(kVK_ANSI_T), "U": UInt32(kVK_ANSI_U),
            "V": UInt32(kVK_ANSI_V), "W": UInt32(kVK_ANSI_W), "X": UInt32(kVK_ANSI_X),
            "Y": UInt32(kVK_ANSI_Y), "Z": UInt32(kVK_ANSI_Z)
        ]

        guard let keyChar = normalized.last, let keyCode = map[keyChar] else {
            return nil
        }

        var modifiers: UInt32 = 0
        if normalized.contains("⌘") { modifiers |= UInt32(cmdKey) }
        if normalized.contains("⌥") { modifiers |= UInt32(optionKey) }
        if normalized.contains("⌃") { modifiers |= UInt32(controlKey) }
        if normalized.contains("⇧") { modifiers |= UInt32(shiftKey) }

        if modifiers == 0 {
            modifiers = UInt32(cmdKey | optionKey)
        }

        return (keyCode, modifiers)
    }

    private func dispatchHotkey(id: UInt32) {
        switch id {
        case xyzHotkeyID:
            DispatchQueue.main.async { self.callback(.xyzToGview) }
        case gviewHotkeyID:
            DispatchQueue.main.async { self.callback(.gviewToXyz) }
        default:
            Logger.shared.warning("Unknown hotkey id: \(id)")
        }
    }

    private static let hotkeyEventHandler: EventHandlerUPP = { _, event, userData in
        guard let userData else { return noErr }

        let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        if status == noErr {
            service.dispatchHotkey(id: hotKeyID.id)
        } else {
            Logger.shared.error("Failed to read hotkey event parameter: \(status)")
        }

        return noErr
    }
}
