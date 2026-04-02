import Foundation

class ConfigStore: ObservableObject {
    static let shared = ConfigStore()
    
    @Published var hotkeyXyzToGview: String = "cmd+alt+x"
    @Published var hotkeyGviewToXyz: String = "cmd+alt+g"
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
        hotkeyXyzToGview = defaults.string(forKey: "hotkey_xyz_to_gview") ?? "cmd+alt+x"
        hotkeyGviewToXyz = defaults.string(forKey: "hotkey_gview_to_xyz") ?? "cmd+alt+g"
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
    }
    
    private func setupDefaultTempDirectory() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: tempDirectory) {
            try? fileManager.createDirectory(atPath: tempDirectory, withIntermediateDirectories: true)
            logger.debug("Temp directory created: \(tempDirectory)")
        }
    }
}
