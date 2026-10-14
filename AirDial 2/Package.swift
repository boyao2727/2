// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AirDial",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "AirDial", targets: ["AirDial"])],
    targets: [
        .target(name: "AirDialCore"),
        .executableTarget(name: "AirDial", dependencies: ["AirDialCore"]),
        // A framework-free check runner also works with Command Line Tools (without Xcode/XCTest).
        .executableTarget(name: "AirDialChecks", dependencies: ["AirDialCore"], path: "Tests/AirDialCoreTests")
    ]
)
