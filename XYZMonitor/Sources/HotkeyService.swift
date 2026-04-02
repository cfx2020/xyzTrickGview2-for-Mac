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

    func registerHotkeys() {
        unregisterHotkeys()

        installEventHandlerIfNeeded()

        let success1 = registerHotkey(
            id: xyzHotkeyID,
            keyCode: UInt32(kVK_ANSI_X),
            modifiers: UInt32(cmdKey | optionKey)
        )
        let success2 = registerHotkey(
            id: gviewHotkeyID,
            keyCode: UInt32(kVK_ANSI_G),
            modifiers: UInt32(cmdKey | optionKey)
        )

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
