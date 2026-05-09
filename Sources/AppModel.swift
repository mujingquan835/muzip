import AppKit
import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedItems: [SelectedItem] = []
    @Published var status: CompressionStatus = .idle
    @Published var history: [CompressionRecord] = []
    @Published var isTargeted = false
    @Published var lastTriggerSource: CompressionTriggerSource = .manual

    private let engine = ZipCompressionEngine()
    private let historyStore = HistoryStore()

    init() {
        history = historyStore.load()
    }

    func selectFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.resolvesAliases = true
        panel.title = "选择要压缩的文件或文件夹"
        panel.prompt = "压缩"

        if panel.runModal() == .OK {
            queueSelection(panel.urls, source: .manual)
            startCompression()
        }
    }

    func handleDrop(urls: [URL]) {
        queueSelection(urls, source: .dragAndDrop)
        startCompression()
    }

    func handleExternalFiles(_ urls: [URL]) {
        queueSelection(urls, source: .finderService)
        bringToFront()
        startCompression()
    }

    func startCompression() {
        let urls = selectedItems.map(\.url)
        guard !urls.isEmpty else { return }

        status = .preparing

        Task {
            do {
                let result = try await engine.compress(urls: urls) { [weak self] progress in
                    Task { @MainActor in
                        self?.status = .running(progress)
                    }
                }

                let record = CompressionRecord(
                    id: UUID(),
                    createdAt: .now,
                    title: result.outputURL.lastPathComponent,
                    sourceSummary: result.sourceSummary,
                    archivePath: result.outputURL.path,
                    archiveSize: result.archiveSize,
                    sourceLabel: lastTriggerSource.label,
                    archivedFileCount: result.archivedFileCount,
                    skippedJunkCount: result.skippedJunkCount,
                    skippedJunkExamples: result.skippedJunkExamples
                )

                history = historyStore.save(record: record)
                status = .finished(record)
                bringToFront()
            } catch {
                status = .failed(error.localizedDescription)
                bringToFront()
            }
        }
    }

    func clearSelection() {
        selectedItems = []
        if case .failed = status {
            status = .idle
        }
    }

    func revealInFinder(_ record: CompressionRecord) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: record.archivePath)])
    }

    private func queueSelection(_ urls: [URL], source: CompressionTriggerSource) {
        let normalized = urls
            .map(\.standardizedFileURL)
            .uniqued(by: \.self)

        guard !normalized.isEmpty else { return }
        lastTriggerSource = source
        selectedItems = normalized.map(SelectedItem.init(url:))
    }

    private func bringToFront() {
        NSApp.setActivationPolicy(.regular)
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
    }
}

extension Array {
    func uniqued<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}
