// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iOS_QA_Framework",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "CompanyiOSKit",
            targets: ["CompanyiOSKit"]
        ),
        .library(
            name: "CompanyTestKit",
            targets: ["CompanyTestKit"]
        ),
        .library(
            name: "iOS_QA_Framework",
            targets: ["CompanyiOSKit"]
        ),
        .executable(
            name: "ProjectTestCenter",
            targets: ["ProjectTestCenter"]
        )
    ],
    targets: [
        .target(
            name: "CompanyiOSKit",
            dependencies: []
        ),
        .target(
            name: "CompanyTestKit",
            dependencies: ["CompanyiOSKit"]
        ),
        .executableTarget(
            name: "ProjectTestCenter",
            dependencies: ["CompanyiOSKit", "CompanyTestKit"]
        ),
        .testTarget(
            name: "CompanyiOSKitTests",
            dependencies: ["CompanyiOSKit", "CompanyTestKit"]
        ),
        .testTarget(
            name: "CompanyTestKitTests",
            dependencies: ["CompanyTestKit"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
