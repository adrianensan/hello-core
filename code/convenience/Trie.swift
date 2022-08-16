import Foundation

extension Character: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    guard let character = try container.decode(String.self).first else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Decoder expected a Character but found an empty string.")
    }
    self = character
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(String(self))
  }
}

public class TrieNode<T: Codable & Hashable>: Codable {
  public private(set) var value: T?
  public private(set) var map: [UInt8: TrieNode]
  
  public static func constructFrom(valuesMap: [String: T]) -> TrieNode {
    let root = TrieNode()
    
    for (key, value) in valuesMap {
      var currentNode: TrieNode = root
      for character in key.utf8 {
        if let node = currentNode.map[character] {
          currentNode = node
          continue
        } else {
          let newNode = TrieNode()
          currentNode.map[character] = newNode
          currentNode = newNode
        }
      }
      currentNode.value = value
    }
    
    return root
  }
  
  public init(value: T? = nil) {
    self.value = value
    self.map = [:]
  }
  
  enum TrieCodingKeys: CodingKey {
    case map
    case value
  }
  
  required public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: TrieCodingKeys.self)
    if let goodMap = try? values.decode([UInt8: TrieNode].self, forKey: .map) {
      map = goodMap
    } else if let oldMap = try? values.decode([Character: TrieNode].self, forKey: .map) {
      map = [:]
      for (key, val) in oldMap {
        map[key.utf8.first!] = val
      }
    } else {
      let oldMap = try values.decode([String: TrieNode].self, forKey: .map)
      map = [:]
      for (key, val) in oldMap {
        map[key.utf8.first!] = val
      }
    }
    if let values = try? values.decode([T].self, forKey: .value), let value = values.first {
      self.value = value
    } else {
      value = try? values.decode(T.self, forKey: .value)
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: TrieCodingKeys.self)
    try container.encode(map, forKey: .map)
    try container.encode(value, forKey: .value)
  }
  
  public func add(value: T, for keys: [String]) {
    for key in keys {
      let key = key.lowercased()
      var currentNode: TrieNode = self
      for character in key.utf8 {
        if let node = currentNode.map[character] {
          currentNode = node
          continue
        } else {
          let newNode = TrieNode()
          currentNode.map[character] = newNode
          currentNode = newNode
        }
      }
      currentNode.value = value
    }
  }
  
  public func exactSearch() -> [T]? {
    return nil
  }
  
  public func traverse(searchTerm: String) -> TrieNode? {
    var node: TrieNode? = self
    for character in searchTerm.utf8 {
      node = node?.map[character]
    }
    return node
  }
  
  public func searchAllTrie() -> Set<T> {
    var results: Set<T> = Set()
    if let value = value {
      results.insert(value)
    }
    
    for node in self.map.values {
      results.formUnion(node.searchAllTrie())
    }
    
    return results
  }
}
