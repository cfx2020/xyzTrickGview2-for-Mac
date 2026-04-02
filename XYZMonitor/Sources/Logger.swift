import Foundation

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

class Logger {
    static let shared = Logger()
    
    private let dateFormatter = DateFormatter()
    private let logQueue = DispatchQueue(label: "com.xyzmonitor.logging")
    
    private var logFileURL: URL?
    private var currentLogLevel: LogLevel = .info
    
    private init() {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        setupLogFile()
    }
    
    func configure(logLevel: LogLevel, logFilePath: String) {
        self.currentLogLevel = logLevel
        if !logFilePath.isEmpty {
            self.logFileURL = URL(fileURLWithPath: logFilePath)
            createLogFileIfNeeded()
        }
    }
    
    func debug(_ message: String) {
        log(level: .debug, message: message)
    }
    
    func info(_ message: String) {
        log(level: .info, message: message)
    }
    
    func warning(_ message: String) {
        log(level: .warning, message: message)
    }
    
    func error(_ message: String) {
        log(level: .error, message: message)
    }
    
    private func log(level: LogLevel, message: String) {
        guard shouldLog(level: level) else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] [\(level.rawValue)] \(message)"
        
        // Console output
        print(logMessage)
        
        // File output
        logQueue.async { [weak self] in
            self?.writeToFile(logMessage)
        }
    }
    
    private func shouldLog(level: LogLevel) -> Bool {
        let levels: [LogLevel] = [.debug, .info, .warning, .error]
        let logIndex = levels.firstIndex(of: currentLogLevel) ?? 1
        let messageIndex = levels.firstIndex(of: level) ?? 1
        return messageIndex >= logIndex
    }
    
    private func setupLogFile() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let appDir = appSupport?.appendingPathComponent("XYZMonitor")
        self.logFileURL = appDir?.appendingPathComponent("xyz_monitor.log")
        createLogFileIfNeeded()
    }
    
    private func createLogFileIfNeeded() {
        guard let logURL = logFileURL else { return }
        
        let fileManager = FileManager.default
        let dirURL = logURL.deletingLastPathComponent()
        
        try? fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true)
        
        if !fileManager.fileExists(atPath: logURL.path) {
            fileManager.createFile(atPath: logURL.path, contents: nil)
        }
    }
    
    private func writeToFile(_ message: String) {
        guard let logURL = logFileURL,
              let data = (message + "\n").data(using: .utf8) else { return }
        
        if let fileHandle = FileHandle(forWritingAtPath: logURL.path) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.closeFile()
        }
    }
}
