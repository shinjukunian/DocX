// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DocX",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10),
        .tvOS(.v9),
        .watchOS(.v3)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "DocX",
            targets: ["DocX"]),
    ],
    dependencies: [
        .package(url: "https://github.com/shinjukunian/AEXML.git", .upToNextMajor(from: "4.6.0")),
//        .package(name: "AEXML", url: "https://github.com/shinjukunian/AEXML.git", .branch("master")),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.0")),
        
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.

        .target(name: "DocX",
                dependencies: ["AEXML", "ZIPFoundation"],
                path: "DocX",
                exclude: ["Info.plist"],
                sources: nil,
                resources: [.copy("blank")],
                publicHeadersPath: nil,
                cSettings: nil,
                cxxSettings: nil,
                swiftSettings: nil,
                linkerSettings: nil
        ),
        
        .testTarget(
            name: "DocXTests",
            dependencies: ["DocX"],
            path: "DocXTests",
            exclude: ["Info.plist"],
            resources: [.copy("blank.docx"), .copy("Picture1.png"), .copy("lenna.png"), .copy("lenna.md"), .copy("styles.xml")]
        ),
        
        .testTarget(
            name: "DocX-iOS-Tests",
            dependencies: ["DocX"],
            path: "DocX-iOS-Tests",
            exclude: ["Info.plist"],
            resources: [.copy("Picture1.png"),.copy("lenna.png"), .copy("lenna.md")]
            )

    ]
)

