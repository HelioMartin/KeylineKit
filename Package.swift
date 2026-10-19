// swift-tools-version: 6.0

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "KeylineKit",
    platforms: [.macOS(.v13), .iOS(.v16), .watchOS(.v9)],
    products: [
        .library(name: "KeylineKit", targets: ["KeylineKit"]),
    ],
    dependencies: [
        // A range across swift-syntax majors keeps the package resolvable next
        // to other macro packages; swift-syntax bumps its major every Swift release.
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"700.0.0"),
    ],
    targets: [
        // Compiler plugin that rewrites the view tree at compile time.
        .macro(
            name: "KeylineKitMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ]
        ),

        // Public macro declarations plus the SwiftUI runtime that measures
        // and draws the annotations.
        .target(name: "KeylineKit", dependencies: ["KeylineKitMacros"]),

        .testTarget(
            name: "KeylineKitMacrosTests",
            dependencies: [
                "KeylineKitMacros",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "KeylineKitTests",
            dependencies: ["KeylineKit"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
