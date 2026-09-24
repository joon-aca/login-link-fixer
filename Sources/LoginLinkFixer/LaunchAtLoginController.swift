import AppKit
import CoreServices
import ServiceManagement

enum LaunchAtLoginState: Equatable {
    case disabled
    case enabled
    case requiresApproval
}

@MainActor
final class LaunchAtLoginController {
    private let service = SMAppService.mainApp

    var state: LaunchAtLoginState {
        switch service.status {
        case .enabled:
            .enabled
        case .requiresApproval:
            .requiresApproval
        case .notRegistered, .notFound:
            .disabled
        @unknown default:
            .disabled
        }
    }

    func toggle() throws {
        switch state {
        case .enabled:
            try service.unregister()
        case .disabled:
            try service.register()
        case .requiresApproval:
            SMAppService.openSystemSettingsLoginItems()
        }
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    static var wasLaunchedAsLoginItem: Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent,
              event.eventID == kAEOpenApplication else {
            return false
        }

        return event.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }
}
