import SwiftUI
import Dispatch

struct ConfigurationView: View {
    @EnvironmentObject var configStore: ConfigStore
    @State private var showFilePicker = false
    @State private var recordingField: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                GeneralTab(recordingField: $recordingField, showFilePicker: $showFilePicker)
            }
            
            Divider()
            
            HStack(spacing: 12) {
                Button(action: {
                    configStore.loadConfiguration()
                    if let window = NSApplication.shared.keyWindow {
                        window.close()
                    }
                }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                
                Button(action: {
                    configStore.saveConfiguration()
                    if let window = NSApplication.shared.keyWindow {
                        window.close()
                    }
                }) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(minWidth: 300, minHeight: 480)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.application],
            onCompletion: { result in
                if case .success(let url) = result {
                    configStore.viewerCommand = url.path
                }
            }
        )
    }
}

struct GeneralTab: View {
    @EnvironmentObject var configStore: ConfigStore
    @Binding var recordingField: String?
    @Binding var showFilePicker: Bool
    
    private enum GeneralField: Hashable {
        case viewerCommand
        case gaussianClipboardPath
        case tempDirectory
        case cleanupDelay
    }

    @FocusState private var focusedField: GeneralField?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // General Section Header
            Text("General")
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            // GView Application
            VStack(alignment: .leading, spacing: 6) {
                Label("GView Application", systemImage: "square.and.arrow.up")
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    TextField("Path to gview", text: $configStore.viewerCommand)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .viewerCommand)
                    
                    Button(action: { showFilePicker = true }) {
                        Image(systemName: "folder")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Gaussian Clipboard Path
            VStack(alignment: .leading, spacing: 6) {
                Label("Gaussian Clipboard Path", systemImage: "doc.text")
                    .fontWeight(.semibold)

                TextField("/Applications/g16/scratch", text: $configStore.gaussianClipboardPath)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .gaussianClipboardPath)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Temporary Directory
            VStack(alignment: .leading, spacing: 6) {
                Label("Temporary Directory", systemImage: "folder.badge.minus")
                    .fontWeight(.semibold)
                
                TextField("Temp dir", text: $configStore.tempDirectory)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .tempDirectory)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Cleanup Delay
            VStack(alignment: .leading, spacing: 6) {
                Label("Cleanup Delay", systemImage: "timer")
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    TextField("Seconds", value: $configStore.cleanupDelaySeconds, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 100)
                        .focused($focusedField, equals: .cleanupDelay)
                    
                    Text("sec")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .padding(.vertical, 8)
            
            // Hotkeys Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Hotkeys")
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    // XYZ → GView Column
                    VStack(alignment: .leading, spacing: 6) {
                        Text("XYZ → GView")
                            .font(.system(.footnote, design: .default))
                            .fontWeight(.semibold)
                        
                        HotkeyCaptureField(
                            value: $configStore.hotkeyXyzToGview,
                            placeholder: "⌘+⌥+X",
                            fieldID: "xyz",
                            recordingField: $recordingField,
                            clearFocus: { focusedField = nil }
                        )
                    }
                    .frame(maxWidth: .infinity)
                    
                    // GView → XYZ Column
                    VStack(alignment: .leading, spacing: 6) {
                        Text("GView → XYZ")
                            .font(.system(.footnote, design: .default))
                            .fontWeight(.semibold)
                        
                        HotkeyCaptureField(
                            value: $configStore.hotkeyGviewToXyz,
                            placeholder: "⌘+⌥+G",
                            fieldID: "gview",
                            recordingField: $recordingField,
                            clearFocus: { focusedField = nil }
                        )
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Reset Button
                    VStack(alignment: .center, spacing: 6) {
                        Text("")
                            .font(.system(.footnote, design: .default))
                        
                        Button(action: {
                            configStore.hotkeyXyzToGview = "⌘+⌥+X"
                            configStore.hotkeyGviewToXyz = "⌘+⌥+G"
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .buttonStyle(.bordered)
                        .help("Reset to default")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if recordingField != nil {
                recordingField = nil
            }
        }
        .onChange(of: focusedField) { newValue in
            if newValue != nil && recordingField != nil {
                recordingField = nil
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct HotkeyCaptureField: View {
    @Binding var value: String
    let placeholder: String
    let fieldID: String
    @Binding var recordingField: String?
    let clearFocus: () -> Void

    @State private var isCapturing = false
    @State private var monitor: Any?
    @State private var lastRecordingField: String? = nil
    @State private var checkTimer: DispatchSourceTimer?
    
    var isOtherFieldRecording: Bool {
        recordingField != nil && recordingField != fieldID
    }

    var body: some View {
        // 液态玻璃风格的快捷键显示框
        HStack(spacing: 10) {
            if isCapturing {
                HStack(spacing: 6) {
                    Image(systemName: "radiowaves.left")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .animation(.easeInOut(duration: 0.6).repeatForever(), value: isCapturing)
                    
                    Text("Recording...")
                        .font(.system(.body, design: .default))
                        .foregroundColor(.secondary)
                }
            } else {
                Text(value.isEmpty ? placeholder : value)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(value.isEmpty ? .secondary : .primary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .opacity(isOtherFieldRecording ? 0.5 : 1.0)
        .onTapGesture {
            if !isCapturing && !isOtherFieldRecording {
                clearFocus()
                recordingField = fieldID
                lastRecordingField = fieldID
                startMonitoring()
            }
        }
        .onChange(of: recordingField) { newValue in
            if isCapturing && newValue != fieldID {
                stopMonitoring()
            }
        }
        .onDisappear { stopMonitoring() }
    }

    private func startMonitoring() {
        isCapturing = true
        
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection([.command, .option, .control, .shift])
            let key = (event.charactersIgnoringModifiers ?? "").uppercased()
            
            guard let first = key.first, first.isLetter else {
                return nil
            }
            
            guard !flags.isEmpty else {
                return nil
            }

            var components: [String] = []
            if flags.contains(.command) { components.append("⌘") }
            if flags.contains(.option) { components.append("⌥") }
            if flags.contains(.control) { components.append("⌃") }
            if flags.contains(.shift) { components.append("⇧") }
            components.append(String(first))
            let result = components.joined(separator: "+")

            self.value = result
            self.isCapturing = false
            self.recordingField = nil
            self.stopMonitoring()
            return nil
        }
        
        // 等待 recordingField 变化或用户按键完成录制
    }

    private func stopMonitoring() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        isCapturing = false
    }
}

struct AboutView: View {
    private let macRepoURL = URL(string: "https://github.com/cfx2020/xyzTrickGview2-for-Mac")!
    private let windowsRepoURL = URL(string: "https://github.com/bane-dysta/xyzTrickGview2")!
    private let personalSiteURL = URL(string: "https://831447.xyz")!
    private let releasesURL = URL(string: "https://github.com/cfx2020/xyzTrickGview2-for-Mac/releases/latest")!
    private var versionText: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        return "v\(shortVersion)-macOS"
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 108, height: 108)

                Image(systemName: "cube.transparent")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            
            Text("XYZ Monitor")
                .font(.title)
                .fontWeight(.bold)
            
            Text(versionText)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("Molecular structure converter")
                .font(.caption)

            Spacer(minLength: 12)

            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    AboutLinkPill(
                        icon: "apple.logo",
                        title: "Mac 版本仓库",
                        destination: macRepoURL
                    )

                    AboutLinkPill(
                        icon: "square.grid.2x2.fill",
                        title: "Windows 原版",
                        destination: windowsRepoURL
                    )
                }

                Button {
                    NSWorkspace.shared.open(releasesURL)
                } label: {
                    Label("检查更新", systemImage: "arrow.clockwise.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .padding(.horizontal, 8)

                Link(destination: personalSiteURL) {
                    Text("Make by Linsay")
                        .underline()
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.blue)
                }
                .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .frame(maxWidth: 380, minHeight: 390)
    }
}

private struct AboutLinkPill: View {
    let icon: String
    let title: String
    let destination: URL

    var body: some View {
        Button {
            NSWorkspace.shared.open(destination)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.blue.opacity(0.55), lineWidth: 1.4)
            )
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}
