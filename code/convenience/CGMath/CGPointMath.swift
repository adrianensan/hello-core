import Foundation

public extension CGPoint {
  
  var magnitude: CGFloat { sqrt(x * x + y * y) }
  
  var maxCoordinateMagnitude: CGFloat { max(abs(x), abs(y)) }
  
  var normalized: CGPoint { self / magnitude }
  
  static prefix func -(point: CGPoint) -> CGPoint {
    point * -1
  }
  
  static func +=(left: inout CGPoint, right: CGPoint) {
    left = left + right
  }
  
  static func -=(left: inout CGPoint, right: CGPoint) {
    left = left - right
  }
  
  static func +(left: CGPoint, right: CGPoint) -> CGPoint {
    CGPoint(x: left.x + right.x, y: left.y + right.y)
  }
  
  static func -(left: CGPoint, right: CGPoint) -> CGPoint {
    CGPoint(x: left.x - right.x, y: left.y - right.y)
  }
  
  static func *(left: CGPoint, right: CGPoint) -> CGPoint {
    CGPoint(x: left.x * right.x, y: left.y * right.y)
  }
  
  static func /(left: CGPoint, right: CGPoint) -> CGPoint {
    CGPoint(x: left.x / right.x, y: left.y / right.y)
  }
  
  static func *(left: CGPoint, right: CGSize) -> CGPoint {
    CGPoint(x: left.x * right.width, y: left.y * right.height)
  }
  
  static func +(left: CGPoint, right: CGSize) -> CGPoint {
    CGPoint(x: left.x + right.width, y: left.y + right.height)
  }
  
  static func -(left: CGPoint, right: CGSize) -> CGPoint {
    CGPoint(x: left.x - right.width, y: left.y - right.height)
  }
  
  // Constants Math
  
  static func +(left: CGPoint, right: CGFloat) -> CGPoint {
    CGPoint(x: left.x + right, y: left.y + right)
  }
  
  static func -(left: CGPoint, right: CGFloat) -> CGPoint {
    CGPoint(x: left.x - right, y: left.y - right)
  }
  
  static func *(left: CGPoint, right: CGFloat) -> CGPoint {
    CGPoint(x: left.x * right, y: left.y * right)
  }
  
  static func *(left: CGFloat, right: CGPoint) -> CGPoint {
    CGPoint(x: left * right.x, y: left * right.y)
  }
  
  static func /(left: CGPoint, right: CGFloat) -> CGPoint {
    CGPoint(x: left.x / right, y: left.y / right)
  }
  
  func dot(with vector: CGPoint) -> CGFloat {
    x * vector.x + y * vector.y
  }
}
