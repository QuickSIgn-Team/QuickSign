import Foundation

struct PlistHelper {
    
    /// Extracts the app name from the Info.plist file within the app bundle.
    /// - Parameter appBundleURL: The URL of the app bundle directory.
    /// - Returns: The app name as a String, or nil if it can't be found.
    static func extractAppName(from appBundleURL: URL) -> String? {
        guard let infoPlistURL = infoPlistURL(from: appBundleURL),
              let plist = NSDictionary(contentsOf: infoPlistURL) else {
            return nil
        }
        
        return plist["CFBundleName"] as? String ?? plist["CFBundleDisplayName"] as? String
    }
    
    /// Extracts the app version from the Info.plist file within the app bundle.
    /// - Parameter appBundleURL: The URL of the app bundle directory.
    /// - Returns: The app version as a String, or nil if it can't be found.
    static func extractAppVersion(from appBundleURL: URL) -> String? {
        guard let infoPlistURL = infoPlistURL(from: appBundleURL),
              let plist = NSDictionary(contentsOf: infoPlistURL) else {
            return nil
        }
        
        return plist["CFBundleShortVersionString"] as? String
    }
    
    /// Returns the URL of the Info.plist file within the app bundle.
    /// - Parameter appBundleURL: The URL of the app bundle directory.
    /// - Returns: The URL of the Info.plist file.
    private static func infoPlistURL(from appBundleURL: URL) -> URL? {
        return appBundleURL.appendingPathComponent("Info.plist")
    }
}
