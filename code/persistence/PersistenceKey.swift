import Foundation

public protocol PersistenceKey: Hashable {
  static var persistence: OFPersistence<Self> { get }
}
