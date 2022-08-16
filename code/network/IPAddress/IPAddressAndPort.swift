import Foundation
import CoreFoundation

public func hostToNetworkByteOrder(_ port: UInt16) -> UInt16 {
  return CFByteOrderGetCurrent() == CFByteOrder(CFByteOrderLittleEndian.rawValue) ? CFSwapInt16(port) : port
}

public func networkToHostByteOrder(_ port: UInt16) -> UInt16 {
  return CFByteOrderGetCurrent() == CFByteOrder(CFByteOrderLittleEndian.rawValue) ? CFSwapInt16(port) : port
}

public struct NetworkAddress: Hashable, Equatable, Codable, CustomStringConvertible {
  public var ipAddress: IPAddress
  public var port: UInt16
  
  public init(ipAddress: IPAddress, port: UInt16) {
    self.ipAddress = ipAddress
    self.port = port
  }
  
  public init(from addr: sockaddr) throws {
    var addr = addr
    switch addr.sa_family {
    case sa_family_t(AF_INET):
      var ipv4 = sockaddr_in()
      memcpy(&ipv4, &addr, MemoryLayout<sockaddr_in>.size)
      ipAddress = .ipv4(try IPv4Address(from: ipv4))
      port = networkToHostByteOrder(ipv4.sin_port)
    case sa_family_t(AF_INET6):
      var ipv6 = sockaddr_in6()
      memcpy(&ipv6, &addr, MemoryLayout<sockaddr_in6>.size)
      ipAddress = .ipv6(try IPv6Address(from: ipv6))
      port = networkToHostByteOrder(ipv6.sin6_port)
    default:
      throw IPAddressError.invalidIPAddressType
    }
  }
  
  public var systemAddr: sockaddr {
    var saddr = sockaddr()
    switch ipAddress {
    case .ipv4(let ipAddress):
      var ipv4Addr = ipAddress.systemAddr
      ipv4Addr.sin_port = hostToNetworkByteOrder(port)
      memcpy(&saddr, &ipv4Addr, MemoryLayout<sockaddr_in>.size)
    case .ipv6(let ipAddress):
      var ipv6Addr = ipAddress.systemAddr
      ipv6Addr.sin6_port = hostToNetworkByteOrder(port)
      memcpy(&saddr, &ipv6Addr, MemoryLayout<sockaddr_in6>.size)
    }
    return saddr
  }
  
  public var string: String {
    "\(ipAddress.string):\(port)"
  }
  
  public var description: String { string }
}
