// swift-tools-version: 6.2
import PackageDescription
let package = Package(name: "TreeSeaCore", platforms: [.iOS(.v17), .macOS(.v14)], products: [.library(name: "TreeSeaCore", type: .dynamic, targets: ["TreeSeaCore"])], targets: [.target(name: "TreeSeaCore", resources: [.process("Resources")]), .testTarget(name: "TreeSeaCoreTests", dependencies: ["TreeSeaCore"], resources: [.process("Fixtures")])], swiftLanguageModes: [.v6])
