import Cocoa

class ClipboardService {
    static let shared = ClipboardService()
    
    private init() {}
    
    func getClipboardText() -> String? {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string)
    }
    
    func setClipboardText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    func getClipboardContents() -> [String: Any]? {
        let pasteboard = NSPasteboard.general
        
        var contents: [String: Any] = [:]
        
        // Try various formats
        if let stringData = pasteboard.string(forType: .string) {
            contents["text"] = stringData
        }
        
        if let rtfData = pasteboard.data(forType: .rtf) {
            contents["rtf"] = rtfData
        }
        
        return contents.isEmpty ? nil : contents
    }
}
