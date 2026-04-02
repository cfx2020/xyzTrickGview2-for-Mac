import Foundation

// MARK: - Data Models

struct Atom {
    let symbol: String
    let x: Double
    let y: Double
    let z: Double
    let atomicNumber: Int
}

struct Molecule {
    let atoms: [Atom]
    let comment: String
    var energy: Double?
    var maxForce: Double?
    var rmsForce: Double?
}

struct ConversionResult {
    let content: String
    let filename: String
}

// MARK: - Enums

enum HotkeyType {
    case xyzToGview
    case gviewToXyz
}

enum ConversionError: LocalizedError {
    case invalidFormat(String)
    case emptyInput
    case parseError(String)
    case viewerNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat(let format):
            return "Invalid \(format) format"
        case .emptyInput:
            return "Input is empty"
        case .parseError(let message):
            return "Parse error: \(message)"
        case .viewerNotFound(let path):
            return "Viewer not found: \(path)"
        }
    }
}

// MARK: - Codable Models

struct ConfigData: Codable {
    var hotkeyXyzToGview: String = "cmd+alt+x"
    var hotkeyGviewToXyz: String = "cmd+alt+g"
    var viewerCommand: String = "/Applications/GaussianView.app/Contents/MacOS/GaussianView"
    var tempDirectory: String = "/tmp/xyz_monitor"
    var cleanupDelaySeconds: Int = 5
    var logLevel: String = "INFO"
    var logFilePath: String = ""
    var lastOpenedDirectory: String = ""
    
    enum CodingKeys: String, CodingKey {
        case hotkeyXyzToGview = "hotkey_xyz_to_gview"
        case hotkeyGviewToXyz = "hotkey_gview_to_xyz"
        case viewerCommand = "viewer_command"
        case tempDirectory = "temp_directory"
        case cleanupDelaySeconds = "cleanup_delay_seconds"
        case logLevel = "log_level"
        case logFilePath = "log_file_path"
        case lastOpenedDirectory = "last_opened_directory"
    }
}
