import PackagePlugin
import Foundation

let configuraionFilename = "AutoCodePatterns.yml"
let generatedFileName = "AutoCodePatterns.Code.swift"

@main
struct CodePatternCommand: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let command = try context.tool(named: "Transformer")
        let configFile = context.package.directory.appending(configuraionFilename)
        try context.package.targets.forEach { target in
            guard let sourceFiles = (target as? SourceModuleTarget)?.sourceFiles else { return }
            try run(command: command.path,
                    with: configFile,
                    for: sourceFiles,
                    in: context.pluginWorkDirectory)
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension CodePatternCommand: XcodeCommandPlugin {
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        let command = try context.tool(named: "Transformer")
        let configFile = context.xcodeProject.directory.appending(configuraionFilename)
        var argExtractor = ArgumentExtractor(arguments)
        let targetNames = argExtractor.extractOption(named: "target")
        let targets = targetNames.isEmpty
        ? context.xcodeProject.targets
        : context.xcodeProject.targets.filter { target in
            targetNames.contains(target.displayName)
        }
        try targets.forEach { target in
            try run(command: command.path,
                    with: configFile,
                    for: target.inputFiles,
                    in: context.pluginWorkDirectory)
        }
    }
}
#endif

extension CodePatternCommand {
    func run(command: Path,
             with config: Path,
             for sourceFiles: FileList,
             in outputDirectoryPath: Path) throws {
        let outputPath = outputDirectoryPath.appending(generatedFileName)
        let toolExec = URL(fileURLWithPath: command.string)
        let toolArgs = ["\(config)", "\(sourceFiles.swiftFiles)", "\(outputPath)"]
        let process = try Process.run(toolExec, arguments: toolArgs)
        process.waitUntilExit()
    }
}

extension PackagePlugin.FileList {
    var swiftFiles: String {
        map { $0.path }
            .filter { $0.extension == "swift" }
            .map { $0.string }
            .joined(separator: ",")
    }
}
