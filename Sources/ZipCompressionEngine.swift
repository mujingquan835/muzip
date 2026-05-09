import Foundation

actor ZipCompressionEngine {
    private let excludedNames: Set<String> = [
        ".DS_Store",
        ".Spotlight-V100",
        ".TemporaryItems",
        ".Trashes",
        ".fseventsd"
    ]

    private let excludedPrefixPaths: [String] = [
        "__MACOSX/"
    ]

    func compress(
        urls: [URL],
        progress: @escaping @Sendable (CompressionProgress) -> Void
    ) async throws -> CompressionResult {
        let scan = try collectFiles(from: urls)
        let files = scan.files
        guard !files.isEmpty else {
            throw CompressionError.noUsableFiles
        }

        progress(.init(completedUnitCount: 0, totalUnitCount: files.count, currentFile: "正在准备压缩任务..."))

        let outputURL = try makeOutputURL(from: urls)
        let rootDirectory = try commonParent(for: urls)
        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.currentDirectoryURL = rootDirectory
        process.arguments = ["-0", "-y", outputURL.path, "-@"]

        let outputPipe = Pipe()
        let inputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        process.standardInput = inputPipe

        let counter = LockedCounter()
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }

            let lines = chunk
                .split(whereSeparator: \.isNewline)
                .map(String.init)
                .filter { $0.contains("adding:") }

            for line in lines {
                let processed = counter.increment()
                let fileName = line
                    .replacingOccurrences(of: "adding:", with: "")
                    .split(separator: "(", maxSplits: 1)
                    .first
                    .map { String($0).trimmingCharacters(in: .whitespaces) } ?? "正在压缩..."

                progress(.init(
                    completedUnitCount: min(processed, files.count),
                    totalUnitCount: files.count,
                    currentFile: fileName
                ))
            }
        }

        try process.run()
        let manifest = files.map(\.relativePath).joined(separator: "\n") + "\n"
        if let manifestData = manifest.data(using: .utf8) {
            inputPipe.fileHandleForWriting.write(manifestData)
        }
        try? inputPipe.fileHandleForWriting.close()
        process.waitUntilExit()
        outputPipe.fileHandleForReading.readabilityHandler = nil

        guard process.terminationStatus == 0 else {
            throw CompressionError.processFailed(process.terminationStatus)
        }

        let archiveSize = try outputURL.resourceValues(forKeys: [.fileSizeKey]).fileSize.map(Int64.init) ?? 0

        return CompressionResult(
            outputURL: outputURL,
            archiveSize: archiveSize,
            sourceSummary: summary(for: urls),
            archivedFileCount: files.count,
            skippedJunkCount: scan.skippedItems.count,
            skippedJunkExamples: Array(scan.skippedItems.prefix(5))
        )
    }

    private func collectFiles(from urls: [URL]) throws -> ScanResult {
        var results: [CollectedFile] = []
        var skippedItems = Set<String>()
        let root = try commonParent(for: urls)

        for url in urls {
            if url.hasDirectoryPath {
                let enumerator = FileManager.default.enumerator(
                    at: url,
                    includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey, .isHiddenKey],
                    options: [.skipsPackageDescendants]
                )

                while let next = enumerator?.nextObject() as? URL {
                    guard shouldInclude(next, skippedItems: &skippedItems) else { continue }
                    let values = try next.resourceValues(forKeys: [.isRegularFileKey])
                    if values.isRegularFile == true {
                        results.append(CollectedFile(url: next, relativePath: relativePath(for: next, root: root)))
                    }
                }
            } else if shouldInclude(url, skippedItems: &skippedItems) {
                results.append(CollectedFile(url: url, relativePath: relativePath(for: url, root: root)))
            }
        }

        return ScanResult(
            files: results.sorted { $0.relativePath.localizedStandardCompare($1.relativePath) == .orderedAscending },
            skippedItems: skippedItems.sorted()
        )
    }

    private func shouldInclude(_ url: URL, skippedItems: inout Set<String>) -> Bool {
        let path = url.path(percentEncoded: false)
        let name = url.lastPathComponent

        if excludedNames.contains(name) {
            skippedItems.insert(name)
            return false
        }
        if name.hasPrefix("._") {
            skippedItems.insert("AppleDouble 资源分支文件")
            return false
        }
        if excludedPrefixPaths.contains(where: path.contains) {
            skippedItems.insert("__MACOSX")
            return false
        }
        return true
    }

    private func commonParent(for urls: [URL]) throws -> URL {
        guard let first = urls.first?.deletingLastPathComponent() else {
            throw CompressionError.noInput
        }

        var components = first.standardizedFileURL.pathComponents

        for candidate in urls.dropFirst().map({ $0.deletingLastPathComponent() }) {
            let nextComponents = candidate.standardizedFileURL.pathComponents
            var index = 0
            while index < min(components.count, nextComponents.count), components[index] == nextComponents[index] {
                index += 1
            }
            components = Array(components.prefix(index))
        }

        guard !components.isEmpty else {
            return URL(fileURLWithPath: "/")
        }

        return URL(fileURLWithPath: NSString.path(withComponents: components), isDirectory: true)
    }

    private func relativePath(for url: URL, root: URL) -> String {
        let standardized = url.standardizedFileURL.path
        let rootPath = root.standardizedFileURL.path
        let trimmed = standardized.hasPrefix(rootPath) ? String(standardized.dropFirst(rootPath.count)) : standardized
        return trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private func makeOutputURL(from urls: [URL]) throws -> URL {
        guard let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            throw CompressionError.unavailableDownloads
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let baseName: String
        if urls.count == 1 {
            baseName = urls[0].deletingPathExtension().lastPathComponent
        } else {
            baseName = "MUZIP-压缩包"
        }

        let datePart = formatter.string(from: .now)
        var candidate = downloads.appendingPathComponent("\(baseName)-\(datePart).zip")
        var suffix = 2

        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = downloads.appendingPathComponent("\(baseName)-\(datePart)-\(suffix).zip")
            suffix += 1
        }

        return candidate
    }

    private func summary(for urls: [URL]) -> String {
        if urls.count == 1 {
            return urls[0].lastPathComponent
        }
        return "\(urls.count) 个项目"
    }
}

private struct CollectedFile {
    let url: URL
    let relativePath: String
}

private struct ScanResult {
    let files: [CollectedFile]
    let skippedItems: [String]
}

private final class LockedCounter: @unchecked Sendable {
    private var value = 0
    private let lock = NSLock()

    func increment() -> Int {
        lock.lock()
        defer { lock.unlock() }
        value += 1
        return value
    }
}

enum CompressionError: LocalizedError {
    case noInput
    case noUsableFiles
    case unavailableDownloads
    case processFailed(Int32)

    var errorDescription: String? {
        switch self {
        case .noInput:
            return "没有选择任何文件。"
        case .noUsableFiles:
            return "过滤系统文件后，没有可压缩的内容。"
        case .unavailableDownloads:
            return "无法定位“下载”文件夹。"
        case .processFailed(let status):
            if status == 12 {
                return "文件数量过多，命令参数已改为清单输入模式，但本次归档仍未成功。"
            }
            return "压缩失败，退出码 \(status)。"
        }
    }
}
