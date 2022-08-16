import Foundation

public class KeychainHelper {
  
  private let service: String
  
  private let accessGroup: String?
  
  #if os(iOS) || os(macOS)
  private var baseAttributes: [CFString: Any] {
    var attributes: [CFString: Any] = [
      kSecAttrService: service,
      kSecClass: kSecClassGenericPassword
    ]
    if let accessGroup = accessGroup {
      attributes[kSecAttrAccessGroup] = accessGroup
    }
    return attributes
  }
  #endif
  
  public init(service: String, group: String? = nil) {
    self.service = service
    accessGroup = group
  }
  
  // MARK: Password
  
  public func set(_ string: String, for key: String) {
    guard string != self.string(for: key),
          let data = string.data(using: .utf8) else {
      return
    }
    
    set(data, for: key)
  }
  
  public func set(_ data: Data, for key: String) {
    #if os(iOS) || os(macOS)
    remove(for: key)
    
    var query = baseAttributes
    query[kSecAttrAccount] = key
    query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
    query[kSecValueData] = data
    
    guard SecItemAdd(query as CFDictionary, nil) == errSecSuccess else {
      return
    }
    #else
    fatalError("Keychain Not Available")
    #endif
  }
  
  @discardableResult public func remove(for key: String) -> Bool {
    #if os(iOS) || os(macOS)
    var query = baseAttributes
    query[kSecAttrAccount] = key
    
    let status = SecItemDelete(query as CFDictionary)
    return status == errSecSuccess
    #else
    fatalError("Keychain Not Available")
    #endif
  }
  
  public func string(for key: String) -> String? {
    guard let data = data(for: key),
          let string = String(data: data, encoding: .utf8) else {
      return nil
    }
    return string
  }
  
  public func data(for key: String) -> Data? {
    #if os(iOS) || os(macOS)
    var query = baseAttributes
    query[kSecAttrAccount] = key
    query[kSecMatchLimit] = kSecMatchLimitOne
    query[kSecReturnData] = true
    
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess,
          let data = result as? Data else {
      return nil
    }
    return data
    #else
    fatalError("Keychain Not Available")
    #endif
  }
  
  public func nuke() {
    #if os(iOS) || os(macOS)
    SecItemDelete(baseAttributes as CFDictionary)
    #else
    fatalError("Keychain Not Available")
    #endif
  }
}
