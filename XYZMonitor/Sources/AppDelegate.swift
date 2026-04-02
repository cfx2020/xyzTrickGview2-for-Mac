import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var configStore = ConfigStore.shared
    var clipboardService = ClipboardService.shared
    var converterService = ConverterService.shared
    var hotkeyService: HotkeyService?
    var logger = Logger.shared
    private var preferencesWindow: NSWindow?
    private var aboutWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("XYZ Monitor macOS app launched")

        if let appIcon = makeCubeTransparentImage() {
            NSApp.applicationIconImage = appIcon
        }
        
        setupStatusBar()
        setupHotkeys()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadHotkeys), name: .xyzMonitorConfigDidSave, object: nil)
        
        // Hide dock icon (menu bar only app)
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            let image = makeCubeTransparentImage()
            button.image = image
        }
        
        let menu = NSMenu()
        menu.showsStateColumn = false
        let convertXyzItem = NSMenuItem(title: "Convert XYZ → GView", action: #selector(convertXyzToGview), keyEquivalent: "x")
        convertXyzItem.target = self
        convertXyzItem.keyEquivalentModifierMask = [.command, .option]
        menu.addItem(convertXyzItem)

        let convertGviewItem = NSMenuItem(title: "Convert GView → XYZ", action: #selector(convertGviewToXyz), keyEquivalent: "g")
        convertGviewItem.target = self
        convertGviewItem.keyEquivalentModifierMask = [.command, .option]
        menu.addItem(convertGviewItem)
        menu.addItem(NSMenuItem.separator())
        let preferencesItem = NSMenuItem(title: "Settings", action: #selector(openPreferences), keyEquivalent: ",")
        preferencesItem.target = self
        preferencesItem.indentationLevel = 0
        menu.addItem(preferencesItem)
        let aboutItem = NSMenuItem(title: "About XYZ Monitor", action: #selector(openAbout), keyEquivalent: "")
        aboutItem.target = self
        aboutItem.indentationLevel = 0
        menu.addItem(aboutItem)
        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }

    private func makeCubeTransparentImage() -> NSImage? {
        NSImage(systemSymbolName: "cube.transparent", accessibilityDescription: "XYZ Monitor")
    }
    
    private func setupHotkeys() {
        hotkeyService = HotkeyService { hotkey in
            switch hotkey {
            case .xyzToGview:
                self.convertXyzToGview()
            case .gviewToXyz:
                self.convertGviewToXyz()
            }
        }
        hotkeyService?.registerHotkeys(
            xyzShortcut: configStore.hotkeyXyzToGview,
            gviewShortcut: configStore.hotkeyGviewToXyz
        )
    }

    @objc private func reloadHotkeys() {
        hotkeyService?.registerHotkeys(
            xyzShortcut: configStore.hotkeyXyzToGview,
            gviewShortcut: configStore.hotkeyGviewToXyz
        )
        logger.info("Global hotkeys reloaded from settings")
    }
    
    @objc func convertXyzToGview() {
        logger.info("User triggered XYZ → GView conversion")
        
        guard let clipboardText = clipboardService.getClipboardText() else {
            showNotification(title: "Error", message: "Clipboard is empty or invalid", isError: true)
            return
        }
        
        do {
            let result = try converterService.convertXyzToGjf(clipboardText)
            openWithViewer(content: result.content, filename: result.filename)
        } catch {
            logger.error("Conversion failed: \(error.localizedDescription)")
            showNotification(title: "Conversion Error", message: error.localizedDescription, isError: true)
        }
    }
    
    @objc func convertGviewToXyz() {
        logger.info("User triggered GView → XYZ conversion")

        do {
            let clipboardFile = try resolveGaussianClipboardFilePath(from: configStore.gaussianClipboardPath)
            let xyzText = try converterService.convertGaussianClipboardFileToXyz(filePath: clipboardFile)
            clipboardService.setClipboardText(xyzText)
        } catch {
            logger.error("Reverse conversion failed: \(error.localizedDescription)")
            showNotification(title: "Conversion Error", message: error.localizedDescription, isError: true)
        }
    }
    
    @objc func openPreferences() {
        logger.info("Opening preferences window")
        NSApp.activate(ignoringOtherApps: true)

        if preferencesWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 540, height: 420),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Settings"
            window.center()
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(
                rootView: ConfigurationView()
                    .environmentObject(configStore)
            )
            preferencesWindow = window
        }

        preferencesWindow?.makeKeyAndOrderFront(self)
        preferencesWindow?.orderFrontRegardless()
    }
    
    @objc func openAbout() {
        NSApp.activate(ignoringOtherApps: true)

        if aboutWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "About XYZ Monitor"
            window.isReleasedWhenClosed = false
            window.center()
            window.contentView = NSHostingView(rootView: AboutView())
            aboutWindow = window
        }

        aboutWindow?.makeKeyAndOrderFront(self)
        aboutWindow?.orderFrontRegardless()
    }
    
    private func openWithViewer(content: String, filename: String) {
        let tempDir = configStore.tempDirectory
        let filePath = (tempDir as NSString).appendingPathComponent(filename)
        
        do {
            try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
            try content.write(toFile: filePath, atomically: true, encoding: .utf8)
            logger.info("Temp file created: \(filePath)")
            
            let viewerPath = configStore.viewerCommand.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !viewerPath.isEmpty else {
                throw ConversionError.viewerNotFound("Empty viewer path")
            }

            let inputURL = URL(fileURLWithPath: filePath)
            
            // Determine if it's an .app bundle or a direct executable path
            let isAppBundle = viewerPath.hasSuffix(".app")
            let isMacOSExecutable = viewerPath.contains("/Contents/MacOS/")
            
            if isAppBundle {
                // Pure .app bundle path (e.g., /Applications/gview.app)
                let appURL = URL(fileURLWithPath: viewerPath)
                logger.info("Opening with .app bundle: \(viewerPath)")
                let conf = NSWorkspace.OpenConfiguration()
                NSWorkspace.shared.open([inputURL], withApplicationAt: appURL, configuration: conf)
            } else if isMacOSExecutable {
                // Full executable path (e.g., /Applications/gview.app/Contents/MacOS/gview)
                // Extract .app bundle path from it
                let fullAppPath = viewerPath.components(separatedBy: ".app").first ?? viewerPath
                if (fullAppPath + ".app").hasSuffix(".app") && FileManager.default.fileExists(atPath: fullAppPath + ".app") {
                    let appURL = URL(fileURLWithPath: fullAppPath + ".app")
                    logger.info("Opening with extracted .app bundle: \(fullAppPath + ".app")")
                    let conf = NSWorkspace.OpenConfiguration()
                    NSWorkspace.shared.open([inputURL], withApplicationAt: appURL, configuration: conf)
                } else {
                    // Fall back to direct executable
                    logger.info("Opening with direct executable: \(viewerPath)")
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: viewerPath)
                    process.arguments = [filePath]
                    try process.run()
                }
            } else {
                // Regular executable file
                logger.info("Opening with direct executable: \(viewerPath)")
                let process = Process()
                process.executableURL = URL(fileURLWithPath: viewerPath)
                process.arguments = [filePath]
                try process.run()
            }

            logger.info("Viewer process started: \(viewerPath)")
            
            // Schedule file cleanup after delay
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(configStore.cleanupDelaySeconds)) {
                try? FileManager.default.removeItem(atPath: filePath)
                self.logger.debug("Temp file cleaned up: \(filePath)")
            }
        } catch {
            logger.error("Failed to open with viewer: \(error.localizedDescription)")
            showNotification(title: "Open Viewer Failed", message: "Viewer path: \(configStore.viewerCommand)\nError: \(error.localizedDescription)", isError: true)
        }
    }

    private func resolveGaussianClipboardFilePath(from path: String) throws -> String {
        let cleaned = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            throw ConversionError.parseError("gaussian clipboard path is empty")
        }

        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: cleaned, isDirectory: &isDir) else {
            throw ConversionError.parseError("Path does not exist: \(cleaned)")
        }

        if !isDir.boolValue {
            return cleaned
        }

        let candidates = [
            (cleaned as NSString).appendingPathComponent("Clipboard.frg"),
            (cleaned as NSString).appendingPathComponent("fragments/Clipboard.frg"),
            (cleaned as NSString).appendingPathComponent("Scratch/fragments/Clipboard.frg")
        ]

        for candidate in candidates where FileManager.default.fileExists(atPath: candidate) {
            return candidate
        }

        if let enumerator = FileManager.default.enumerator(atPath: cleaned) {
            while let entry = enumerator.nextObject() as? String {
                if entry.hasSuffix("Clipboard.frg") {
                    return (cleaned as NSString).appendingPathComponent(entry)
                }
            }
        }

        throw ConversionError.parseError("Cannot find Clipboard.frg under: \(cleaned)")
    }
    
    private func showNotification(title: String, message: String, isError: Bool = false) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = isError ? .warning : .informational
            alert.runModal()
        }
    }
}
