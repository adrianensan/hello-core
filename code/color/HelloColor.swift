import Foundation

public struct HelloColor: Codable, Equatable, Hashable {
  public var r: Double
  public var g: Double
  public var b: Double
  public var a: Double
  
  static func cap(_ value: Double) -> Double {
    min(1, max(0, value))
  }
  
  public init(r: Double, g: Double, b: Double, a: Double = 1) {
    self.r = Self.cap(r)
    self.g = Self.cap(g)
    self.b = Self.cap(b)
    self.a = Self.cap(a)
  }
  
  public init(h: Double, s: Double, b: Double, a: Double = 1) {
    let h = Self.cap(h)
    let s = Self.cap(s)
    let b = Self.cap(b)
    let maxV = b
    let minV = maxV * (1 - s)
    
    let z = (maxV - minV) * (1 - abs((h * 6).truncatingRemainder(dividingBy: 2) - 1))
    
    let section = Int(h * 6)
    switch section {
    case 0:
      self.r = maxV
      self.g = z + minV
      self.b = minV
    case 1:
      self.r = z + minV
      self.g = maxV
      self.b = minV
    case 2:
      self.r = minV
      self.g = maxV
      self.b = z + minV
    case 3:
      self.r = minV
      self.g = z + minV
      self.b = maxV
    case 4:
      self.r = z + minV
      self.g = minV
      self.b = maxV
    default:
      self.r = maxV
      self.g = minV
      self.b = z + minV
    }
    self.a = Self.cap(a)
  }
  
  public init?(hexCode: String) {
    var hexCode: String = hexCode.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if (hexCode.hasPrefix("#")) {
      hexCode.removeFirst()
    }
    
    let scanner = Scanner(string: hexCode)
    var hexNumber: UInt64 = 0
    
    guard hexCode.count == 6, scanner.scanHexInt64(&hexNumber) else {
      return nil
    }
    
    self.init(r: Double((hexNumber & 0xFF0000) >> 16) / 255.0,
              g: Double((hexNumber & 0x00FF00) >> 8) / 255.0,
              b: Double((hexNumber & 0x0000FF)) / 255.0)
  }
  
  public var light: HelloColor { self }
  
  public var dark: HelloColor { self }
  
  public func opacity(_ alpha: CGFloat) -> HelloColor {
    HelloColor(r: r, g: g, b: b, a: a * alpha)
  }
  
  var brightness: Double {
    r * 0.225 + g * 0.7 + b * 0.075
  }
  
  var isDark: Bool {
    brightness < 0.7
  }
  
  var isDim: Bool {
    brightness < 0.4
  }
  
  var isGreyscale: Bool {
    r == b && b == g
  }
  
  var isEssentiallyGreyscale: Bool {
    abs(r - b) < 0.1 && abs(b - g) < 0.1
  }
  
  public var readableOverlayColor: HelloColor {
    isDark ? .white : .black
  }
  
  public var alpha: CGFloat { a }
  
  public var hsb: (Double, Double, Double) {
    let minV = min(r, g, b)
    let maxV = max(r, g, b)
    let delta = maxV - minV
    
    var hue: Double
    if delta == 0 {
      hue = 0
    } else if r == maxV {
      hue = (g - b) / delta
    } else if g == maxV {
      hue = 2 + (b - r) / delta
    } else {
      hue = 4 + (r - g) / delta
    }
    hue *= 60
    if hue < 0 {
      hue += 360
    }
    hue /= 360
    let saturation = maxV == 0 ? 0 : (delta / maxV)
    let brightness = maxV
    
    return (hue, saturation, brightness)
  }
  
  public func modify(saturation: Double, brightness: Double) -> HelloColor {
    var (h, s, b) = hsb
    if s > 0 {
      s += saturation
    }
    
    b += brightness
    return HelloColor(h: h, s: s, b: b, a: a)
  }
  
  public func withFakeAlpha(_ alpha: Double, background: HelloColor) -> HelloColor {
    HelloColor(r: r * alpha + background.r * (1 - alpha),
               g: g * alpha + background.g * (1 - alpha),
               b: b * alpha + background.b * (1 - alpha),
               a: a)
  }
}

public extension HelloColor {
  static var transparent: HelloColor { HelloColor(r: 0, g: 0, b: 0, a: 0) }
  static var black: HelloColor { HelloColor(r: 0, g: 0, b: 0) }
  static var white: HelloColor { HelloColor(r: 1, g: 1, b: 1) }
}
