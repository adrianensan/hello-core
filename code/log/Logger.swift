import Foundation

@MainActor
public protocol LoggerSubscriber: AnyObject {
  func statementLogged()
}

public actor Logger {
  
  public let logFile: URL
  public private(set) var logStatements: [LogStatement]
  public weak var subscriber: LoggerSubscriber?
  
  private var lastLoggedTime: TimeInterval = 0
  private var isFlushPending: Bool = false
  private var isEphemeral: Bool = false
  
  public init(logFile: URL, ephemeral: Bool = false) {
    self.logFile = logFile
    self.isEphemeral = ephemeral
    if !ephemeral,
        let data = try? Data(contentsOf: logFile),
       let logStatements = try? JSONDecoder().decode([LogStatement].self, from: data) {
      self.logStatements = logStatements
    } else {
      logStatements = []
    }
    
    if !FileManager.default.fileExists(atPath: logFile.deletingLastPathComponent().path) {
      try? FileManager.default.createDirectory(at: logFile.deletingLastPathComponent(), withIntermediateDirectories: true)
    }
  }
  
  private func generateRawString() -> String {
    logStatements.reduce("") { $0 + $1.formattedLine + "\n" }
  }
  
  public func log(_ logStatement: LogStatement) async throws {
    logStatements.append(logStatement)
    guard !isEphemeral else { return }
    self.lastLoggedTime = Date().timeIntervalSince1970
    Task { await self.subscriber?.statementLogged() }
    if !self.isFlushPending {
      self.isFlushPending = true
      try await flush()
    }
  }
  
  public func clear() async throws {
    logStatements = []
    Task { await subscriber?.statementLogged() }
    if !isFlushPending {
      isFlushPending = true
      try await flush()
    }
  }
  
  public func subscribe(_ subscriber: LoggerSubscriber) {
    self.subscriber = subscriber
  }
  
  public func flush(force: Bool = false) async throws {
    guard !force else {
      flushReal()
      isFlushPending = false
      return
    }
    guard isFlushPending else { return }
    var diff = Date().timeIntervalSince1970 - lastLoggedTime
    while diff < 5 {
      try await Task.sleep(nanoseconds: UInt64(5 - diff) * 1_000_000_000)
      diff = Date().timeIntervalSince1970 - lastLoggedTime
    }
    isFlushPending = false
    let oldestAllowed = Date().timeIntervalSince1970 - 60 * 60 * 24 * 2
    logStatements = Array(logStatements.drop(while: { $0.timeStamp < oldestAllowed }))
    flushReal()
  }
  
  private func flushReal() {
    guard let logStatementsDate = try? JSONEncoder().encode(logStatements) else { return }
    try? logStatementsDate.write(to: logFile)
  }
}
