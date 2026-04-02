import Foundation

extension Notification.Name {
    static let xyzMonitorConfigDidSave = Notification.Name("xyzMonitorConfigDidSave")
}

class ConfigStore: ObservableObject {
    static let shared = ConfigStore()
    
    @Published var hotkeyXyzToGview: String = "⌘+⌥+X"
    @Published var hotkeyGviewToXyz: String = "⌘+⌥+G"
    @Published var viewerCommand: String = "/Applications/gview.app"
    @Published var gaussianClipboardPath: String = "/Applications/g16/scratch"
    @Published var tempDirectory: String = "/tmp/xyz_monitor"
    @Published var cleanupDelaySeconds: Int = 5
    @Published var logLevel: String = "INFO"
    @Published var logFilePath: String = ""
    
    private let defaults = UserDefaults.standard
    private let logger = Logger.shared
    
    private init() {
        loadConfiguration()
        setupDefaultTempDirectory()
    }
    
    func loadConfiguration() {
        hotkeyXyzToGview = normalizeHotkey(defaults.string(forKey: "hotkey_xyz_to_gview") ?? "⌘⌥X")
        hotkeyGviewToXyz = normalizeHotkey(defaults.string(forKey: "hotkey_gview_to_xyz") ?? "⌘⌥G")
        viewerCommand = defaults.string(forKey: "viewer_command") ?? "/Applications/gview.app"
        gaussianClipboardPath = defaults.string(forKey: "gaussian_clipboard_path") ?? "/Applications/g16/scratch"
        tempDirectory = defaults.string(forKey: "temp_directory") ?? "/tmp/xyz_monitor"
        cleanupDelaySeconds = defaults.integer(forKey: "cleanup_delay_seconds")
        if cleanupDelaySeconds == 0 { cleanupDelaySeconds = 5 }
        logLevel = defaults.string(forKey: "log_level") ?? "INFO"
        logFilePath = defaults.string(forKey: "log_file_path") ?? ""
        
        // Configure logger with loaded values
        if let level = LogLevel(rawValue: logLevel) {
            logger.configure(logLevel: level, logFilePath: logFilePath)
        }
    }
    
    func saveConfiguration() {
        defaults.set(hotkeyXyzToGview, forKey: "hotkey_xyz_to_gview")
        defaults.set(hotkeyGviewToXyz, forKey: "hotkey_gview_to_xyz")
        defaults.set(viewerCommand, forKey: "viewer_command")
        defaults.set(gaussianClipboardPath, forKey: "gaussian_clipboard_path")
        defaults.set(tempDirectory, forKey: "temp_directory")
        defaults.set(cleanupDelaySeconds, forKey: "cleanup_delay_seconds")
        defaults.set(logLevel, forKey: "log_level")
        defaults.set(logFilePath, forKey: "log_file_path")
        defaults.synchronize()
        logger.info("Configuration saved")
        NotificationCenter.default.post(name: .xyzMonitorConfigDidSave, object: nil)
    }
    
    private func setupDefaultTempDirectory() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: tempDirectory) {
            try? fileManager.createDirectory(atPath: tempDirectory, withIntermediateDirectories: true)
            logger.debug("Temp directory created: \(tempDirectory)")
        }
    }

    private func normalizeHotkey(_ value: String) -> String {
        let normalized = value.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "cmd", with: "⌘")
            .replacingOccurrences(of: "alt", with: "⌥")
        
        // Normalize format to ⌘+⌥+X style
        switch normalized {
        case "⌘⌥x", "⌘+⌥+x", "cmd+alt+x":
            return "⌘+⌥+X"
        case "⌘⌥g", "⌘+⌥+g", "cmd+alt+g":
            return "⌘+⌥+G"
        default:
            return value
        }
    }
}
