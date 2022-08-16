import Foundation

public protocol BaseAppIcon: Codable, Equatable, Identifiable, CaseIterable {
  
  init?(rawValue: String)
  
  static var defaultIcon: Self { get }
  
  static var collections: [AppIconCollection<Self>] { get }
  
  var rawValue: String { get }
  
  var displayName: String { get }
  
  var isFree: Bool { get }
}

public extension BaseAppIcon {
  var id: String {
    rawValue
  }
  
  var imageName: String {
    "app-icon-\(rawValue)"
  }
  
  var systemName: String? {
    switch self {
    case Self.defaultIcon: return nil
    default: return imageName
    }
  }
  
  static var allIcons: [Self] { Array(allCases) }
  
  static func infer(from systemName: String?) -> Self {
    if let systemName = systemName {
      return Self(rawValue: systemName.deletingPrefix("app-icon-")) ?? defaultIcon
    } else {
      return defaultIcon
    }
  }
}

public struct AppIconCollection<AppIcon: BaseAppIcon> {
  
  public enum AppIconCollectionLayout: Equatable {
    case grid
    case gridWithLabels
    case list
  }
  
  public var id: String
  public var name: String?
  public var icons: [AppIcon]
  public var layout: AppIconCollectionLayout
  
  public init(id: String = UUID().uuidString,
              name: String? = nil,
              icons: [AppIcon],
              layout: AppIconCollectionLayout) {
    self.id = id
    self.name = name
    self.icons = icons
    self.layout = layout
  }
}
