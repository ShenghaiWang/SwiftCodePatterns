// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "SwiftCodePatterns",
    platforms: [
        .macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9)
    ],
    products: [
        .plugin(name: "Code Patterns Command", targets: ["Code Patterns Command"]),
        .plugin(name: "Code Patterns BuildTool", targets: ["Code Patterns BuildTool"]),
    ],
    targets: [
        .plugin(name: "Code Patterns Command",
                capability: .command(intent:
                        .custom(verb: "Run Code Patterns",
                                description: "Generate code based on the AutoCodePatterns.yml configuration")),
                dependencies: ["Transformer"]
               ),
        .plugin(name: "Code Patterns BuildTool",
                capability: .buildTool(),
                dependencies: ["Transformer"]),
        .binaryTarget(name: "Transformer", path: "./Transformer.artifactbundle")
    ]
)
