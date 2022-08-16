import Foundation

public extension String {
  func deletingPrefix(_ prefix: String) -> String {
    guard self.hasPrefix(prefix) else { return self }
    return String(dropFirst(prefix.count))
  }
  
  func deletingSuffix(_ suffix: String) -> String {
    guard self.hasSuffix(suffix) else { return self }
    return String(dropLast(suffix.count))
  }
}
