import Foundation

public typealias HTTPHeaderKey = String

public extension HTTPHeaderKey {
  static var location: HTTPHeaderKey { "Location" }
}

public struct HelloUserAgent {
  public var appName: String
  public var appVersion: AppVersion
  public var deviceOS: String
  public var deviceName: String
}

public struct HTTPRequest<Body: Codable>: HTTPRequestConformable {
  
  public var clientAddress: NetworkAddress
  
  public var method: HTTPMethod
  
  public var url: String
  
  public var headers: [HTTPHeaderKey: String]
  
  public var cookies: [String : String]
  
  public var body: Body
  
  public var host: String? { headers["host"] }
  public var userAgent: String? { headers["user-agent"] }
  
  public var helloUserAgent: HelloUserAgent? {
    guard let userAgent else { return nil }
    let userAgentComponenets = userAgent.components(separatedBy: ";")
    guard userAgentComponenets.count == 4,
          let appVersion = AppVersion(userAgentComponenets[1].trimmingCharacters(in: .whitespaces))
    else { return nil }
    
    return HelloUserAgent(appName: userAgentComponenets[0].trimmingCharacters(in: .whitespaces),
                          appVersion: appVersion,
                          deviceOS: userAgentComponenets[2].trimmingCharacters(in: .whitespaces),
                          deviceName: userAgentComponenets[3].trimmingCharacters(in: .whitespaces))
  }
  
  public init(clientAddress: NetworkAddress, method: HTTPMethod, url: String, headers: [HTTPHeaderKey : String], cookies: [String : String], body: Body) {
    self.clientAddress = clientAddress
    self.method = method
    self.url = url
    self.headers = headers
    self.cookies = cookies
    self.body = body
  }
  
  public init(copying otherRequest: HTTPRequest<some Codable>, body: Body) {
    self.init(clientAddress: otherRequest.clientAddress,
              method: otherRequest.method,
              url: otherRequest.url,
              headers: otherRequest.headers,
              cookies: otherRequest.cookies,
              body: body)
  }
}

public protocol HTTPRequestConformable<RequestBodyType> {
  
  associatedtype RequestBodyType: Codable = Data?
  
  var clientAddress: NetworkAddress { get }
  var httpVersion: HTTPVersion { get }
  var method: HTTPMethod { get }
  var url: String { get }
  var host: String? { get }
  var cookies: [String: String] { get }
  var body: RequestBodyType { get }
}


public extension HTTPRequestConformable {
  var httpVersion: HTTPVersion { .http1_1 }
  var body: Data? { nil }
}
