import SwiftUI

@main
struct XYZMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            ConfigurationView()
                .environmentObject(appDelegate.configStore)
        }
    }
}
