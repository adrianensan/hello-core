import Foundation

public enum IPAddressError: Error {
  case invalidIPAddress
  case invalidIPv4Address
  case invalidIPAddressType
}

protocol IPAddressConformable: Codable, Equatable, Hashable {
  var type: IPVersion { get }
  var bytes: [UInt8] { get }
  var string: String { get }
}

public enum IPAddress: IPAddressConformable {
  case ipv4(IPv4Address)
  case ipv6(IPv6Address)
  
  public init(from string: String) throws {
    do {
      self = .ipv4(try IPv4Address(string))
    } catch {
      self = .ipv6(try IPv6Address(string))
    }
  }
  
  public init(from clientAddrressStruct: sockaddr) throws {
    var clientAddrressStruct = clientAddrressStruct
    switch clientAddrressStruct.sa_family {
    case sa_family_t(AF_INET):
      var ipv4 = sockaddr_in()
      memcpy(&ipv4, &clientAddrressStruct, MemoryLayout<sockaddr_in>.size)
      self = .ipv4(try IPv4Address(from: ipv4))
    case sa_family_t(AF_INET6):
      var ipv6 = sockaddr_in6()
      memcpy(&ipv6, &clientAddrressStruct, MemoryLayout<sockaddr_in6>.size)
      self = .ipv6(try IPv6Address(from: ipv6))
    default:
      throw IPAddressError.invalidIPAddressType
    }
  }
  
  public var type: IPVersion {
    switch self {
    case .ipv4(let address): return address.type
    case .ipv6(let address): return address.type
    }
  }
  
  public var bytes: [UInt8] {
    switch self {
    case .ipv4(let address): return address.bytes
    case .ipv6(let address): return address.bytes
    }
  }
  
  public var string: String {
    switch self {
    case .ipv4(let address): return address.string
    case .ipv6(let address): return address.string
    }
  }
  
  public var systemAddr: sockaddr {
    var saddr = sockaddr()
    switch self {
    case .ipv4(let ipAddress):
      var ipv4Addr = ipAddress.systemAddr
      memcpy(&saddr, &ipv4Addr, MemoryLayout<sockaddr_in>.size)
    case .ipv6(let ipAddress):
      var ipv6Addr = ipAddress.systemAddr
      memcpy(&saddr, &ipv6Addr, MemoryLayout<sockaddr_in6>.size)
    }
    return saddr
  }
}

public extension IPAddress {
  static var localhost: IPAddress { .ipv4(.init(127, 0, 0, 1)) }
}
