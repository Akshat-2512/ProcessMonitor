import CoreServices
import Foundation
import Observation

@Observable
class ProcessStore {
    var processes: [ProcessInfo] = []

    private var fsStream: FSEventStreamRef?
    private let monDir: URL

    init() {
        monDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".process_monitor")
        load()
        startWatching()
    }

    deinit {
        if let stream = fsStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
    }

    private func startWatching() {
        let path = monDir.path as CFString
        let paths = [path] as CFArray

        // Pass unretained self — ProcessStore lives for the app's lifetime.
        var ctx = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil, release: nil, copyDescription: nil
        )

        let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            let store = Unmanaged<ProcessStore>.fromOpaque(info).takeUnretainedValue()
            DispatchQueue.main.async { store.load() }
        }

        // 0.2s latency — reacts almost instantly when mon writes a status file.
        fsStream = FSEventStreamCreate(
            nil, callback, &ctx, paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.2,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagNone)
        )

        if let stream = fsStream {
            FSEventStreamSetDispatchQueue(stream, .main)
            FSEventStreamStart(stream)
        }
    }

    func load() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: monDir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else {
            processes = []
            return
        }

        processes = files
            .filter { $0.pathExtension == "json" }
            .sorted {
                let a = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let b = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return a > b
            }
            .compactMap { url in
                guard let data = try? Data(contentsOf: url),
                      var proc = try? JSONDecoder().decode(ProcessInfo.self, from: data) else { return nil }
                if let logPath = proc.log {
                    proc = proc.withLogLines(readLogLines(logPath, count: 60))
                }
                return proc
            }
    }

    private func readLogLines(_ path: String, count: Int) -> [String] {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let text = String(data: data, encoding: .utf8) else { return [] }
        return text
            .components(separatedBy: "\n")
            .flatMap { $0.components(separatedBy: "\r") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .suffix(count)
            .map { Self.stripAnsi($0) }
    }

    private static func stripAnsi(_ s: String) -> String {
        guard s.contains("\u{1B}") else { return s }
        return s.replacingOccurrences(of: "\u{1B}[[0-9;]*[mGKHFJABCDsu]",
                                      with: "", options: .regularExpression)
    }

    func kill(pid: Int) {
        // SIGTERM the child process; mon notices the exit and writes final status.
        Darwin.kill(pid_t(pid), SIGTERM)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.load()
        }
    }

    var running: [ProcessInfo] { processes.filter(\.running) }
    var done: [ProcessInfo]    { processes.filter { !$0.running } }

    var menuBarTitle: String {
        if running.count == 1 {
            let p = running[0]
            var parts = [p.name]
            if let cpu = p.cpu_pct     { parts.append(String(format: "%.0f%%", cpu)) }
            if let mem = p.formattedMem { parts.append(mem) }
            if let e = p.elapsed       { parts.append(e) }
            return parts.joined(separator: " · ")
        }
        if running.count > 1 { return "\(running.count) running" }
        if !done.isEmpty      { return "Idle" }
        return "Processes"
    }
}
