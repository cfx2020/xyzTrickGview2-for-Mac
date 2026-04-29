import Foundation
import ServiceManagement

class LaunchAtLoginService {
    static let shared = LaunchAtLoginService()

    private let logger = Logger.shared

    private init() {}

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        guard enabled != isEnabled else {
            logger.debug("Launch at login already \(enabled ? "enabled" : "disabled")")
            return
        }

        if enabled {
            try SMAppService.mainApp.register()
            logger.info("Launch at login enabled")
        } else {
            try SMAppService.mainApp.unregister()
            logger.info("Launch at login disabled")
        }
    }
}
