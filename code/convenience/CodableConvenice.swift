import Foundation

public extension Encodable {
  func data() throws -> Data {
    try JSONEncoder().encode(self)
  }
}

public extension Decodable {
  
  static func decode(from data: Data) throws -> Self {
    try JSONDecoder().decode(Self.self, from: data)
  }
}
