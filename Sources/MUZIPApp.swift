import SwiftUI

@main
struct MUZIPApp: App {
    @StateObject private var model = AppModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 860, minHeight: 620)
                .onAppear {
                    appDelegate.model = model
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            SidebarCommands()
            CommandGroup(after: .newItem) {
                Button("选择文件进行压缩") {
                    model.selectFiles()
                }
                .keyboardShortcut("o")
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let pendingLaunchFlag = "--muzip-launch-visible"
    weak var model: AppModel? {
        didSet {
            flushPendingURLsIfPossible()
        }
    }
    private let launchedForPendingRequest = CommandLine.arguments.contains("--muzip-launch-visible")
    private var pendingExternalURLs: [URL] = CommandLine.arguments
        .dropFirst()
        .filter { $0 != "--muzip-launch-visible" }
        .map(URL.init(fileURLWithPath:))
        .filter { FileManager.default.fileExists(atPath: $0.path) }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = self
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL(fileURLWithPath: $0) }
        enqueue(urls)
        sender.reply(toOpenOrPrint: .success)
    }

    @objc func compressSelection(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        let urls = readServiceURLs(from: pasteboard)
        guard !urls.isEmpty else {
            error.pointee = "MUZIP 没有收到可压缩的文件或文件夹。"
            return
        }

        do {
            try PendingLaunchRequestStore().save(urls: urls)
            try launchVisibleApp()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                NSApp.terminate(nil)
            }
        } catch let launchError {
            error.pointee = launchError.localizedDescription as NSString
        }
    }

    private func enqueue(_ urls: [URL]) {
        let filtered = urls.filter { FileManager.default.fileExists(atPath: $0.path) }
        guard !filtered.isEmpty else { return }
        pendingExternalURLs.append(contentsOf: filtered)
        flushPendingURLsIfPossible()
    }

    private func flushPendingURLsIfPossible() {
        guard let model else { return }
        let storedURLs = launchedForPendingRequest ? ((try? PendingLaunchRequestStore().loadAndClear()) ?? []) : []
        let urls = (pendingExternalURLs + storedURLs)
            .map(\.standardizedFileURL)
            .uniqued(by: \.self)
        guard !urls.isEmpty else { return }
        pendingExternalURLs.removeAll()
        Task { @MainActor in
            model.handleExternalFiles(urls)
        }
    }

    private func readServiceURLs(from pasteboard: NSPasteboard) -> [URL] {
        if let fileURLs = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL], !fileURLs.isEmpty {
            return fileURLs
        }

        let legacyType = NSPasteboard.PasteboardType("NSFilenamesPboardType")
        if let paths = pasteboard.propertyList(forType: legacyType) as? [String] {
            return paths.map(URL.init(fileURLWithPath:))
        }

        return []
    }

    private func launchVisibleApp() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-n", "-a", Bundle.main.bundlePath, "--args", pendingLaunchFlag]
        try process.run()
    }
}

private struct PendingLaunchRequestStore {
    private var fileURL: URL {
        let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let directory = supportDirectory.appendingPathComponent("MUZIP", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("pending-request.json")
    }

    func save(urls: [URL]) throws {
        let payload = urls.map(\.path)
        let data = try JSONEncoder().encode(payload)
        try data.write(to: fileURL, options: .atomic)
    }

    func loadAndClear() throws -> [URL] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        try? FileManager.default.removeItem(at: fileURL)
        let paths = try JSONDecoder().decode([String].self, from: data)
        return paths.map(URL.init(fileURLWithPath:))
    }
}
