import AppKit
import Carbon

@MainActor
final class HotkeyManager {
    nonisolated(unsafe) private var hotkeyRef: EventHotKeyRef?
    nonisolated(unsafe) private var eventHandlerRef: EventHandlerRef?
    private let action: () -> Void

    init(action: @escaping () -> Void) { self.action = action }

    deinit {
        if let hotkeyRef { UnregisterEventHotKey(hotkeyRef) }
        if let eventHandlerRef { RemoveEventHandler(eventHandlerRef) }
    }

    func register() {
        var ref: EventHotKeyRef?
        let identifier = EventHotKeyID(signature: fourCharCode("LLFX"), id: 1)
        RegisterEventHotKey(0x25, UInt32(optionKey | cmdKey), identifier, GetApplicationEventTarget(), 0, &ref)
        hotkeyRef = ref

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard event != nil, let userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async { manager.action() }
                return noErr
            },
            1,
            &eventType,
            pointer,
            &eventHandlerRef
        )
    }
}

private func fourCharCode(_ value: String) -> FourCharCode {
    value.utf8.prefix(4).reduce(0) { ($0 << 8) + FourCharCode($1) }
}
