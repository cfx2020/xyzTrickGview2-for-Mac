import SwiftUI

struct ConfigurationView: View {
    @EnvironmentObject var configStore: ConfigStore
    @State private var showFilePicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("XYZ Monitor")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Molecular structure conversion")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding()
            
            TabView {
                GeneralTab()
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }
                
                HotkeysTab()
                    .tabItem {
                        Label("Hotkeys", systemImage: "keyboard")
                    }
            }
            .padding()
            
            HStack(spacing: 12) {
                Button(action: { configStore.saveConfiguration() }) {
                    Text("Save").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: { configStore.loadConfiguration() }) {
                    Text("Cancel").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 300)
    }
}

struct GeneralTab: View {
    @EnvironmentObject var configStore: ConfigStore
    @State private var showFilePicker = false
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Viewer Application", systemImage: "square.and.arrow.up")
                    .fontWeight(.semibold)
                
                HStack {
                    TextField("Path to viewer", text: $configStore.viewerCommand)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: { showFilePicker = true }) {
                        Image(systemName: "folder")
                    }
                    .buttonStyle(.bordered)
                }
                
                Text("Path to molecular viewer (e.g., GaussianView)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Temporary Directory", systemImage: "folder.badge.minus")
                    .fontWeight(.semibold)
                
                TextField("Temp dir", text: $configStore.tempDirectory)
                    .textFieldStyle(.roundedBorder)
                
                Text("Directory for temporary files")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Gaussian Clipboard Path", systemImage: "doc.text")
                    .fontWeight(.semibold)

                TextField("/Applications/g16/scratch", text: $configStore.gaussianClipboardPath)
                    .textFieldStyle(.roundedBorder)

                Text("Directory or file path used by reverse conversion (Clipboard.frg)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Cleanup Delay", systemImage: "timer")
                    .fontWeight(.semibold)
                
                Stepper(value: $configStore.cleanupDelaySeconds, in: 1...60, step: 1) {
                    Text("\(configStore.cleanupDelaySeconds) sec")
                }
                
                Text("Wait time before cleanup")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
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

struct HotkeysTab: View {
    @EnvironmentObject var configStore: ConfigStore
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label("XYZ → Viewer", systemImage: "arrow.right")
                    .fontWeight(.semibold)
                
                HStack {
                    TextField("cmd+alt+x", text: $configStore.hotkeyXyzToGview)
                        .textFieldStyle(.roundedBorder)
                    Text("(⌘⌥X)").font(.caption).foregroundColor(.gray)
                }
                
                Text("Convert clipboard XYZ")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Viewer → XYZ", systemImage: "arrow.left")
                    .fontWeight(.semibold)
                
                HStack {
                    TextField("cmd+alt+g", text: $configStore.hotkeyGviewToXyz)
                        .textFieldStyle(.roundedBorder)
                    Text("(⌘⌥G)").font(.caption).foregroundColor(.gray)
                }
                
                Text("Convert structure to XYZ")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("XYZ Monitor")
                .font(.title)
                .fontWeight(.bold)
            
            Text("v1.0.0-macOS")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("Molecular structure converter")
                .font(.caption)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: 300)
    }
}
