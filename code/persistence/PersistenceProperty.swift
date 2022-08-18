import Foundation

public enum PersistenceType {
  case defaults(key: String)
  case file(path: String)
  case keychain(key: String)
  case memory
}

public struct NoOld<Key: PersistenceKey>: PersistenceProperty {
  
  public var key: Key
  
  public var defaultValue: Bool? { nil }
  
  public var location: PersistenceType { .defaults(key: "nil") }
  
  public typealias Value = Bool?
  
  public init(key: Key) {
    self.key = key
  }
  
}

public protocol PersistenceProperty {
  
  associatedtype Value: Codable
  associatedtype Key: PersistenceKey
  associatedtype OldProperty: PersistenceProperty = NoOld<Key>
  
  var defaultValue: Value { get }
  
  var location: PersistenceType { get }
  
  var key: Key { get }
  
  var isDeprecated: Bool { get }
  
  var allowCache: Bool { get }
  
  func cleanup(value: Value) -> Value
  
//  func migrate(from oldValue: OldProperty.Value) -> Value?
}

extension PersistenceProperty {
  public func cleanup(value: Value) -> Value { value }
  
  public var allowCache: Bool { true }
  public var isDeprecated: Bool { false }
//  public func migrate(from oldValue: OldProperty.Value) -> Value? { nil }
}

@MainActor
fileprivate class PersistentThingInternal<Property: PersistenceProperty>: PersistenceSubscriber {
  
  private let persistence: OFPersistence<Property.Key>
  private let property: Property
  
  var value: Property.Value
  
  init(persistence: OFPersistence<Property.Key>, property: Property) {
    self.persistence = persistence
    self.property = property
    value = Persistence.value(property)
    persistence.subscribe(self, to: property.key)
  }
  
  public func update(to newValue: Property.Value) {
    persistence.save(newValue, for: property)
  }
  
  public func valueUpdated<Key: PersistenceKey>(for key: Key) {
    value = Persistence.value(property)
  }
}

@propertyWrapper
public class PersistentThing<Property: PersistenceProperty>: PersistenceSubscriber {
  
  private let persistence: OFPersistence<Property.Key>
  private let property: Property
  var value: Property.Value
  
  public init(_ property: Property, in persistence: OFPersistence<Property.Key> = Property.Key.persistence) {
    self.persistence = persistence
    self.property = property
    value = Persistence.value(property)
    persistence.subscribe(self, to: property.key)
  }
  
  public var wrappedValue: Property.Value {
    get { value }
    set {
      value = newValue
      update(to: newValue)
    }
  }
  
  public func update(to newValue: Property.Value) {
    persistence.save(newValue, for: property)
  }
  
  public func valueUpdated<Key: PersistenceKey>(for key: Key) {
    value = Persistence.value(property)
  }
}
