// swift-tools-version: 5.7
import PackageDescription

let package = Package(
  name: "HelloCore",
  platforms: [.iOS(.v15), .macOS(.v12)],
  products: [
    .library(name: "HelloCore", targets: ["HelloCore"])
  ],
  targets: [
    .target(name: "HelloCore",
            dependencies: [],
            path: "code",
            swiftSettings: [.define("DEBUG", .when(configuration: .debug))])
  ]
)
