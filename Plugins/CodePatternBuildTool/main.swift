import Foundation
import PackagePlugin

let configuraionFilename = "AutoCodePatterns.yml"
let generatedFileName = "AutoCodePatterns.Code.swift"

@main
struct CodePatternBuildTool: BuildToolPlugin {
    func createBuildCommands(context: PackagePlugin.PluginContext, target: PackagePlugin.Target) async throws -> [PackagePlugin.Command] {
        let configFile = context.package.directory.appending(configuraionFilename)
        guard let sourceFiles = target.sourceModule?.sourceFiles else { return [] }
        let command = try context.tool(named: "Transformer")
        return [createBuildCommand(for: command.path,
                                   with: configFile,
                                   for: sourceFiles,
                                   in: context.pluginWorkDirectory)]
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension CodePatternBuildTool: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodeProjectPlugin.XcodePluginContext, target: XcodeProjectPlugin.XcodeTarget) throws -> [PackagePlugin.Command] {
        let command = try context.tool(named: "Transformer")
        let configFile = context.xcodeProject.directory.appending(configuraionFilename)
        return [createBuildCommand(for: command.path,
                                   with: configFile,
                                   for: target.inputFiles,
                                   in: context.pluginWorkDirectory)]
    }
}
#endif

extension CodePatternBuildTool {
    func createBuildCommand(for command: Path,
                            with config: Path,
                            for sourceFiles: FileList,
                            in outputDirectoryPath: Path) -> Command {
        let outputPath = outputDirectoryPath.appending(generatedFileName)
        return .buildCommand(displayName: "Generating \(outputPath)",
                             executable: command,
                             arguments: ["\(config)",
                                         "\(sourceFiles.swiftFiles.map({ $0.string }).joined(separator: ","))",
                                         "\(outputPath)"],
                             inputFiles: sourceFiles.swiftFiles,
                             outputFiles: [outputPath]
        )
    }
}

extension PackagePlugin.FileList {
    var swiftFiles: [Path] {
        map { $0.path }
            .filter { $0.extension == "swift" }
    }
}
