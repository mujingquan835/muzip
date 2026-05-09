import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.91, green: 0.95, blue: 0.99),
                    Color(red: 0.97, green: 0.98, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            MeshBackdrop()
                .ignoresSafeArea()

            mainPanel
                .padding(28)
        }
    }

    private var mainPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            dropZone
            statusPanel
        }
        .padding(26)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 30, x: 0, y: 20)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 18) {
            Image("MUZIPLogo")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 82, height: 82)
                .shadow(color: Color(red: 0.08, green: 0.38, blue: 0.96).opacity(0.22), radius: 18, x: 0, y: 10)

            VStack(alignment: .leading, spacing: 10) {
                Text("MUZIP")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                Text("拖进去，或者右键使用 MUZIP 压缩。ZIP 会保存到“下载”目录。")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    BadgeView(text: "ZIP / STORE")
                    BadgeView(text: "过滤 macOS 垃圾文件")
                    BadgeView(text: "Finder 右键")
                }
            }
        }
    }

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.16),
                            Color.white.opacity(0.45)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 1.5, dash: [8, 9])
                )
                .foregroundStyle(model.isTargeted ? Color.accentColor : Color.accentColor.opacity(0.35))

            VStack(spacing: 16) {
                Image("MUZIPLogo")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 92, height: 92)

                Text("把文件或文件夹拖到这里")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))

                Text("MUZIP 会过滤 macOS 垃圾文件，把 ZIP 保存到“下载”目录。")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)

                Button("选择并压缩") {
                    model.selectFiles()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(26)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 270)
        .overlay {
            FileDropReceiver(
                isTargeted: $model.isTargeted,
                onDrop: { urls in
                    model.handleDrop(urls: urls)
                }
            )
        }
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("压缩状态")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                Spacer()
                Text("输出位置：下载 / {名称}-YYYY-MM-DD.zip")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            switch model.status {
            case .idle:
                HStack(spacing: 14) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("已就绪")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                        Text("拖拽或选择文件后会立即开始压缩。")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

            case .preparing:
                Label("正在整理待压缩文件...", systemImage: "gearshape.2.fill")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

            case .running(let progress):
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(progress.currentFile)
                            .lineLimit(1)
                        Spacer()
                        Text(progress.percentText)
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))

                    ProgressView(value: progress.fractionCompleted)
                        .tint(.accentColor)
                        .scaleEffect(x: 1, y: 1.4, anchor: .center)
                }

            case .finished(let record):
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(Color.green)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("压缩包已创建")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                            Text(record.title)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("在 Finder 中显示") {
                            model.revealInFinder(record)
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack(spacing: 12) {
                        StatusMetric(title: "来源", value: record.sourceLabel ?? "MUZIP")
                        StatusMetric(title: "已归档", value: "\(record.archivedFileCount ?? 0) 个文件")
                        StatusMetric(title: "已过滤", value: "\(record.skippedJunkCount ?? 0) 项")
                    }

                    if let examples = record.skippedJunkExamples, !examples.isEmpty {
                        Text("已过滤：\(examples.joined(separator: "、"))")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.red)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var isBusy: Bool {
        if case .preparing = model.status { return true }
        if case .running = model.status { return true }
        return false
    }
}

private struct BadgeView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.7), in: Capsule())
    }
}

private struct StatusMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct MeshBackdrop: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .fill(Color(red: 0.09, green: 0.47, blue: 0.98).opacity(0.18))
                    .frame(width: proxy.size.width * 0.45)
                    .blur(radius: 14)
                    .offset(x: -proxy.size.width * 0.24, y: -proxy.size.height * 0.24)

                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: proxy.size.width * 0.35)
                    .blur(radius: 30)
                    .offset(x: proxy.size.width * 0.26, y: -proxy.size.height * 0.28)

                Circle()
                    .fill(Color(red: 0.36, green: 0.78, blue: 0.95).opacity(0.14))
                    .frame(width: proxy.size.width * 0.28)
                    .blur(radius: 18)
                    .offset(x: proxy.size.width * 0.2, y: proxy.size.height * 0.2)
            }
        }
    }
}

private struct FileDropReceiver: NSViewRepresentable {
    @Binding var isTargeted: Bool
    let onDrop: ([URL]) -> Void

    func makeNSView(context: Context) -> DropTargetView {
        let view = DropTargetView()
        view.delegate = context.coordinator
        return view
    }

    func updateNSView(_ nsView: DropTargetView, context: Context) {
        nsView.delegate = context.coordinator
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isTargeted: $isTargeted, onDrop: onDrop)
    }

    final class Coordinator: NSObject, DropTargetViewDelegate {
        @Binding private var isTargeted: Bool
        private let onDrop: ([URL]) -> Void

        init(isTargeted: Binding<Bool>, onDrop: @escaping ([URL]) -> Void) {
            _isTargeted = isTargeted
            self.onDrop = onDrop
        }

        func dropTargetDidUpdate(isTargeted: Bool) {
            self.isTargeted = isTargeted
        }

        func dropTargetDidReceive(urls: [URL]) {
            onDrop(urls)
        }
    }
}

private protocol DropTargetViewDelegate: AnyObject {
    func dropTargetDidUpdate(isTargeted: Bool)
    func dropTargetDidReceive(urls: [URL])
}

private final class DropTargetView: NSView {
    weak var delegate: DropTargetViewDelegate?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let urls = extractURLs(from: sender)
        let accepts = !urls.isEmpty
        delegate?.dropTargetDidUpdate(isTargeted: accepts)
        return accepts ? .copy : []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        delegate?.dropTargetDidUpdate(isTargeted: false)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = extractURLs(from: sender)
        delegate?.dropTargetDidUpdate(isTargeted: false)
        guard !urls.isEmpty else { return false }
        delegate?.dropTargetDidReceive(urls: urls)
        return true
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        !extractURLs(from: sender).isEmpty
    }

    private func extractURLs(from sender: NSDraggingInfo) -> [URL] {
        guard let fileURLs = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] else {
            return []
        }
        return fileURLs
            .map(\.standardizedFileURL)
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }
}
