// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "SwiftCodePatterns",
    platforms: [
        .macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9)
    ],
    products: [
        .plugin(name: "CodePatternCommand", targets: ["CodePatternCommand"]),
        .plugin(name: "CodePatternBuildTool", targets: ["CodePatternBuildTool"]),
    ],
    targets: [
        .plugin(name: "CodePatternCommand",
                capability: .command(intent:
                        .custom(verb: "Run CodePatterns",
                                description: "Running CodePatterns will generate code based on the AutoCodePatterns.yml configuration")),
                dependencies: ["Transformer"]
               ),
        .plugin(name: "CodePatternBuildTool",
                capability: .buildTool(),
                dependencies: ["Transformer"]),
        .binaryTarget(name: "Transformer", path: "./Transformer.artifactbundle")
    ]
)
