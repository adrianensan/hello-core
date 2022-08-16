import Foundation

extension String {
  
  static let lineBreak: String = "\r\n"
  
  var data: Data { data(using: .utf8) ?? Data() }
  
  var filterNewlines: String { filter{ !String.lineBreak.contains($0) } }
  
  var trimWhitespace: String { trimmingCharacters(in: .whitespaces) }
  var trimNewlines: String { trimmingCharacters(in: .newlines) }
  
  var fileExtension: String? {
    let splits = split(separator: "/", omittingEmptySubsequences: true)
    guard let fileName = splits.last else { return nil }
    let fileNameSplits = fileName.split(separator: ".")
    guard let potentialFileExtension = fileNameSplits.last else { return nil }
    return String(potentialFileExtension)
  }
}
//
//public typealias RawHTTPResponse = HTTPResponse<Data?>
extension HTTPResponse<Data?> {
//  
//  public init(closure: (ResponseBuilder) -> ()) {
//    let responseBuilder = ResponseBuilder()
//    closure(responseBuilder)
//    self.init(responseBuilder: responseBuilder)
//  }
//  
//  init(responseBuilder: ResponseBuilder) {
//    status = responseBuilder.status
//    cache = responseBuilder.cache
//    cookies = responseBuilder.cookies
//    customeHeaders = responseBuilder.customeHeaders
//    contentType = responseBuilder.contentType
//    location = responseBuilder.location
//    lastModifiedDate = responseBuilder.lastModifiedDate
//    body = responseBuilder.body
//  }
//  
  public var bodyAsString: String? {
    if let body = body, let data = body {
      return String(data: data, encoding: .utf8)
    } else {
      return nil
    }
  }
//  
  private var headerString: String {
    var string: String = httpVersion.description + " " + status.description + .lineBreak
    string += "Server: Hello" + .lineBreak
    if let cache = cache { string += cache.description + .lineBreak }
    if let location = location { string += Header.locationPrefix + location + .lineBreak }
    string += "\(Header.datePrefix)" + Header.httpDateFormater.string(from: Date()) + .lineBreak
    string += "\(Header.connection)keep-alive" + .lineBreak
    for cookie in cookies { string += cookie.description + .lineBreak }
    if let lastModifiedDate = lastModifiedDate { string += Header.lastModifiedPrefix + Header.httpDateFormater.string(from: lastModifiedDate) + .lineBreak }
    for customHeader in customeHeaders { string += customHeader + .lineBreak }
    
    if let body = body, let data = body {
      if let contentType = contentType {
        switch contentType {
        case .none: break
        default: string += contentType.description + .lineBreak
        }
      }
      
      string += "\(Header.contentEncodingPrefix)identity" + .lineBreak
      string += "\(Header.contentLengthPrefix)\(data.count)" + .lineBreak
    } else {
      string += "\(Header.contentLengthPrefix)0" + .lineBreak
    }
    string += "strict-transport-security: max-age=15552000; includeSubDomains" + .lineBreak
    return string + .lineBreak
  }
  
  public var data: Data {
    var data = headerString.data
    if !omitBody, let body = body, let bodyData = body { data += bodyData }
    return data
  }
}
//
public struct HTTPResponse<Body: Codable> {
  
  public static var ok: HTTPResponse<Body> { HTTPResponse(status: .ok) }
  public static var notFound: HTTPResponse<Body> { HTTPResponse(status: .notFound) }
  public static var unauthorized: HTTPResponse<Body> { HTTPResponse(status: .unauthorized) }
  public static var badRequest: HTTPResponse<Body> { HTTPResponse(status: .badRequest) }
  public static var serverError: HTTPResponse<Body> { HTTPResponse(status: .internalServerError) }
  
  public static func ok(body: Body, contentType: ContentType? = nil, omitBody: Bool = false) -> HTTPResponse<Body> {
    HTTPResponse(status: .ok, contentType: contentType, body: body)
  }
  
  public let httpVersion: HTTPVersion = .http1_1
  public let status: HTTPResponseStatus
  public var cache: Cache?
  public let cookies: [Cookie]
  public let customeHeaders: [String]
  public let contentType: ContentType?
  public let location: String?
  public let lastModifiedDate: Date?
  public let body: Body?
  public let omitBody: Bool
  
  public init(status: HTTPResponseStatus,
              cache: Cache? = nil,
              cookies: [Cookie] = [],
              customeHeaders: [String] = [],
              contentType: ContentType? = nil,
              location: String? = nil,
              lastModifiedDate: Date? = nil,
              body: Body? = nil,
              omitBody: Bool = false) {
    self.status = status
    self.cache = cache
    self.cookies = cookies
    self.customeHeaders = customeHeaders
    if contentType == nil {
      switch Body.self {
      case is Data.Type, is Data?.Type:
        self.contentType = nil
      case is String.Type, is String?.Type:
        self.contentType = .plain
      default:
        self.contentType = .json
      }
    } else {
      self.contentType = contentType
    }
    self.location = location
    self.lastModifiedDate = lastModifiedDate
    self.body = body
    self.omitBody = omitBody
  }
  
  public init(copying otherResponse: HTTPResponse<some Codable>, body: Body) {
    self.init(status: otherResponse.status,
              cache: otherResponse.cache,
              cookies: otherResponse.cookies,
              customeHeaders: otherResponse.customeHeaders,
              contentType: otherResponse.contentType,
              location: otherResponse.location,
              lastModifiedDate: otherResponse.lastModifiedDate,
              body: body)
  }
}
//
//extension RawHTTPResponse: CustomStringConvertible {
//  public var description: String {
//    var string = headerString
//    if let bodyString = bodyAsString { string += bodyString + .lineBreak }
//    return string
//  }
//}
