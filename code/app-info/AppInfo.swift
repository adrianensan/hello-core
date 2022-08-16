import Foundation

public enum App {
  public static let bundleID: String = Bundle.main.bundleIdentifier ?? "?"
  public static let version: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
  public static let build: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
  public static let name: String = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "?"
  public static let displayName: String = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "?"
  public static let copyright: String = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? "?"
  
  #if targetEnvironment(simulator)
  public static let isTestBuild = true
  #else
  public static let isTestBuild = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
  #endif
  
  public static var rootBundleID: String {
    if bundleID.hasSuffix(".widget") {
      return String(bundleID.dropLast(7))
    } else if bundleID.hasSuffix(".watchkitapp") {
      return String(bundleID.dropLast(12))
    } else if bundleID.hasSuffix(".watchkitapp.watchkitextension") {
      return String(bundleID.dropLast(30))
    } else {
      return bundleID
    }
  }
  public static var appGroup: String { "group.\(rootBundleID)" }
  public static var iCloudContainer: String { "iCloud.\(rootBundleID)" }
}
