import Foundation

public extension CGFloat {
  var normalized: CGFloat { self < 0 ? -1 : 1 }
}

