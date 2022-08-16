import Foundation

public protocol PersistenceSubscriber: AnyObject {
  
  @MainActor func valueUpdated<Key: PersistenceKey>(for key: Key)
}

public class Weak<T: AnyObject> {
  public weak var value : T?
  public init (value: T) {
    self.value = value
  }
}

open class OFPersistence<Key: PersistenceKey> {
  
  public let defaults: UserDefaults
  public let keychain: KeychainHelper
  
  public private(set) var baseURL: URL
  private var allowSaving: Bool = true
  
  public func fileURL(for subPath: String) -> URL {
    baseURL.appendingPathComponent(subPath)
  }
  
  private var subscribers: [Key: [Weak<AnyObject>]] = [:]
  private var cache: [Key: Any] = [:]
  
  public init(defaults: UserDefaults, pathRoot: URL, keychain: KeychainHelper) {
    self.defaults = defaults
    self.baseURL = pathRoot
    self.keychain = keychain
    if !FileManager.default.fileExists(atPath: baseURL.path) {
      try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }
  }
  
  private func valueChanged(forKey key: Key) {
    DispatchQueue.main.async {
      self.subscribers[key] = self.subscribers[key]?.filter { $0.value != nil }
      self.subscribers[key]?.forEach { ($0.value as? PersistenceSubscriber)?.valueUpdated(for: key) }
    }
  }
  
  public func subscribe<Subscriber: PersistenceSubscriber>(_ subscriber: Subscriber, to key: Key) {
    subscribers[key] = (subscribers[key] ?? []) + [Weak(value: subscriber as AnyObject)]
  }
  
  public func unsubscribe<Subscriber: PersistenceSubscriber>(_ subscriber: Subscriber, from key: Key) {
    subscribers[key] = subscribers[key]?.filter { $0.value !== subscriber }
  }
  
  public func save<Property: PersistenceProperty>(_ value: Property.Value, for property: Property) where Property.Key == Key {
    guard allowSaving else { return }
    if property.isDeprecated {
      Log.warning("Using depreacted property \(property.key)", context: "Persistence")
    }
    let value = property.cleanup(value: value)
    if property.allowCache {
      cache[property.key] = value
    }
    
    switch property.location {
    case .defaults(let key):
      switch Property.Value.self {
      case is Bool.Type, is Bool?.Type,
           is String.Type, is String?.Type,
           is Int.Type, is Int?.Type,
           is Double.Type, is Double?.Type,
           is Data.Type, is Data?.Type:
        if let value =
            value as? Bool? ??
            value as? String? ??
            value as? Int? ??
            value as? Double? ??
            value as? Data?,
           value == nil {
          defaults.removeObject(forKey: key)
          return
        }
        defaults.set(value, forKey: key)
      default:
        guard let data = try? JSONEncoder().encode(value) else {
          defaults.removeObject(forKey: key)
          return
        }
        defaults.set(data, forKey: key)
      }
    case .file(let path):
      let url = fileURL(for: path)
      do {
        if !FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path) {
          try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        }
      } catch {
//        Log.error("Failed to create directory for \(path). Error: \(error.localizedDescription)", context: "Persistence")
      }
      
      if let string = value as? String {
        try? string.write(to: url, atomically: false, encoding: .utf8)
      } else {
        var data: Data? = value as? Data
        if data == nil {
          data = try? JSONEncoder().encode(value)
        }
        try? data?.write(to: url)
      }
    case .keychain(let key):
      if let string = value as? String? {
        if let string = string {
          keychain.set(string, for: key)
        } else {
          keychain.remove(for: key)
        }
      }
    case .memory: break
    }
    valueChanged(forKey: property.key)
  }
  
  public func value<Property: PersistenceProperty>(for property: Property) -> Property.Value where Property.Key == Key {
    if let rawValue = cache[property.key],
       let value = rawValue as? Property.Value {
      return value
    }
    
    let returnValue: Property.Value
    
    switch property.location {
    case .defaults(let key):
      switch Property.Value.self {
      case is Bool.Type, is Bool?.Type,
        is String.Type, is String?.Type,
        is Int.Type, is Int?.Type,
        is Double.Type, is Double?.Type,
        is Data.Type, is Data?.Type:
        returnValue = defaults.object(forKey: key) as? Property.Value ?? property.defaultValue
      default:
        guard let data = defaults.object(forKey: key) as? Data,
              let value = try? JSONDecoder().decode(Property.Value.self, from: data) else {
          returnValue = property.defaultValue
          break
        }
        returnValue = value
      }
    case .file(let path):
      let url = fileURL(for: path)
      switch Property.Value.self {
      case is String.Type, is String?.Type:
        returnValue = (try? String(contentsOf: url) as? Property.Value) ?? property.defaultValue
      default:
        guard let data = try? Data(contentsOf: url) else {
          returnValue = property.defaultValue
          break
        }
        switch Property.Value.self {
        case is Data.Type, is Data?.Type:
          returnValue = (data as? Property.Value) ?? property.defaultValue
        default:
          guard let value = try? JSONDecoder().decode(Property.Value.self, from: data) else {
            returnValue = property.defaultValue
            break
          }
          returnValue = value
        }
      }
    case .keychain(let key):
      switch Property.Value.self {
      case is String.Type, is String?.Type:
        returnValue = keychain.string(for: key) as? Property.Value ?? property.defaultValue
      default:
        guard let data = keychain.data(for: key) else {
          returnValue = property.defaultValue
          break
        }
        switch Property.Value.self {
        case is Data.Type, is Data?.Type:
          returnValue = (data as? Property.Value) ?? property.defaultValue
        default:
          guard let value = try? JSONDecoder().decode(Property.Value.self, from: data) else {
            returnValue = property.defaultValue
            break
          }
          returnValue = value
        }
      }
    case .memory: returnValue = property.defaultValue
    }
    
    let value = property.cleanup(value: returnValue)
    if property.allowCache {
      cache[property.key] = value
    }
    
    return value
  }
  
  public func delete<Property: PersistenceProperty>(property: Property) where Property.Key == Key {
    cache[property.key] = nil
    
    switch property.location {
    case .defaults(let key): defaults.removeObject(forKey: key)
    case .file(let path): try? FileManager.default.removeItem(atPath: fileURL(for: path).path)
    case .keychain(let key): keychain.remove(for: key)
    case .memory: break
    }
    valueChanged(forKey: property.key)
  }
  
  public func nuke(stopSaving: Bool = true) {
    allowSaving = !stopSaving
    cache = [:]
    for key in defaults.dictionaryRepresentation().keys {
      defaults.removeObject(forKey: key)
    }
    print(defaults.dictionaryRepresentation())
    
    keychain.nuke()
    
    guard let enumerator = FileManager.default.enumerator(at: baseURL, includingPropertiesForKeys: nil) else { return }
    for file in enumerator {
      if let fileURL = file as? URL {
        try? FileManager.default.removeItem(at: fileURL)
      }
    }
  }
}

public enum Persistence {
  public static func save<Property: PersistenceProperty>(_ value: Property.Value, for property: Property) {
    Property.Key.persistence.save(value, for: property)
  }
  
  public static func value<Property: PersistenceProperty>(_ property: Property) -> Property.Value {
    Property.Key.persistence.value(for: property)
  }
  
  public static func delete<Property: PersistenceProperty>(_ property: Property) {
    Property.Key.persistence.delete(property: property)
  }
  
  public static func subscribe<Subscriber: PersistenceSubscriber, Key: PersistenceKey>(_ subscriber: Subscriber, to key: Key) {
    Key.persistence.subscribe(subscriber, to: key)
  }
  
  public static func unsubscribe<Subscriber: PersistenceSubscriber, Key: PersistenceKey>(_ subscriber: Subscriber, from key: Key) {
    Key.persistence.unsubscribe(subscriber, from: key)
  }
}
