import Foundation

struct SelectedItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL

    var displayName: String {
        url.lastPathComponent
    }

    var iconName: String {
        url.hasDirectoryPath ? "folder.fill" : "doc.fill"
    }
}

enum CompressionTriggerSource: String, Codable {
    case manual
    case dragAndDrop
    case finderService

    var label: String {
        switch self {
        case .manual:
            return "手动选择"
        case .dragAndDrop:
            return "拖拽到 MUZIP"
        case .finderService:
            return "Finder 右键服务"
        }
    }
}

struct CompressionProgress: Equatable {
    var completedUnitCount: Int
    var totalUnitCount: Int
    var currentFile: String

    var fractionCompleted: Double {
        guard totalUnitCount > 0 else { return 0 }
        return Double(completedUnitCount) / Double(totalUnitCount)
    }

    var percentText: String {
        "\(Int((fractionCompleted * 100).rounded()))%"
    }
}

struct CompressionRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let title: String
    let sourceSummary: String
    let archivePath: String
    let archiveSize: Int64
    let sourceLabel: String?
    let archivedFileCount: Int?
    let skippedJunkCount: Int?
    let skippedJunkExamples: [String]?

    init(
        id: UUID,
        createdAt: Date,
        title: String,
        sourceSummary: String,
        archivePath: String,
        archiveSize: Int64,
        sourceLabel: String? = nil,
        archivedFileCount: Int? = nil,
        skippedJunkCount: Int? = nil,
        skippedJunkExamples: [String]? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.sourceSummary = sourceSummary
        self.archivePath = archivePath
        self.archiveSize = archiveSize
        self.sourceLabel = sourceLabel
        self.archivedFileCount = archivedFileCount
        self.skippedJunkCount = skippedJunkCount
        self.skippedJunkExamples = skippedJunkExamples
    }
}

enum CompressionStatus: Equatable {
    case idle
    case preparing
    case running(CompressionProgress)
    case finished(CompressionRecord)
    case failed(String)
}

struct CompressionResult {
    let outputURL: URL
    let archiveSize: Int64
    let sourceSummary: String
    let archivedFileCount: Int
    let skippedJunkCount: Int
    let skippedJunkExamples: [String]
}
