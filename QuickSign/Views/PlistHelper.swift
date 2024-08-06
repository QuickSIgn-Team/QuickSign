import Foundation

struct PlistHelper {
    static func extractAppName(from appBundleURL: URL) -> String? {
        guard let infoPlistURL = infoPlistURL(from: appBundleURL),
              let plist = NSDictionary(contentsOf: infoPlistURL) else {
            return nil
        }
        
        return plist["CFBundleName"] as? String ?? plist["CFBundleDisplayName"] as? String
    }
    
    static func extractAppVersion(from appBundleURL: URL) -> String? {
        guard let infoPlistURL = infoPlistURL(from: appBundleURL),
              let plist = NSDictionary(contentsOf: infoPlistURL) else {
            return nil
        }
        
        return plist["CFBundleShortVersionString"] as? String
    }
    
    private static func infoPlistURL(from appBundleURL: URL) -> URL? {
        return appBundleURL.appendingPathComponent("Info.plist")
    }
}
