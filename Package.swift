// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BTPeripheral",
	platforms: [
        .macOS(.v10_15),
	],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/pvieito/PythonKit", from: "0.3.1"),
        //.package(url: "https://github.com/pvieito/PythonKit", from: "0.2.2"),
        //.package("Sources/BTPeripheral/sendArduino.py")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.

        .executableTarget(
            name: "BTPeripheral",
            dependencies: [
                .product(name: "PythonKit", package: "PythonKit")
            ]),
        .testTarget(
            name: "BTPeripheralTests",
            dependencies: ["BTPeripheral"]),
    ]
)
