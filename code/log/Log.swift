import Foundation

public enum Log {
  
  #if DEBUG
  public static var shouldPrintStatements: Bool = true
  #else
  public static var shouldPrintStatements: Bool = false
  #endif
  
  public static var ephemeral: Bool = false
  
  private static var logsFolder: URL { FileManager.default.temporaryDirectory.appendingPathComponent("logs") }
  
  public static var logger: Logger = Logger(logFile: logsFolder.appendingPathComponent("prod.txt"), ephemeral: true)
  
  private static func log(level: LogLevel, message: String, context: String) {
    let logStatement = LogStatement(level: level, message: message, context: context)
    if shouldPrintStatements {
      print(logStatement.formattedLine)
    }

    if level != .debug && level != .verbose {
      Task { try await logger.log(logStatement) }
    }
  }
  
  public static func verbose(_ message: String, context: String) {
    log(level: .verbose, message: message, context: context)
  }
  
  public static func debug(_ message: String, context: String) {
    log(level: .debug, message: message, context: context)
  }
  
  public static func info(_ message: String, context: String) {
    log(level: .info, message: message, context: context)
  }
  
  public static func warning(_ message: String, context: String) {
    log(level: .warning, message: message, context: context)
  }
  
  public static func error(_ message: String, context: String) {
    log(level: .error, message: message, context: context)
  }
}

