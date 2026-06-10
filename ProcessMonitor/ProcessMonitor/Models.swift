import Foundation

struct ProcessInfo: Identifiable, Codable {
    let pid: Int
    let name: String
    let cmd: String?
    let running: Bool
    let elapsed: String?
    let cpu_pct: Double?
    let mem_mb: Double?
    let last_lines: [String]?
    let log_lines: [String]?
    let log: String?
    let exit_code: Int?

    var id: Int { pid }

    var succeeded: Bool { (exit_code ?? 0) == 0 }

    var formattedMem: String? {
        guard let mb = mem_mb else { return nil }
        return mb >= 1024
            ? String(format: "%.2f GB", mb / 1024)
            : String(format: "%.0f MB", mb)
    }

    var memFraction: Double {
        guard let mb = mem_mb else { return 0 }
        return min(mb / (16 * 1024), 1.0)
    }

    var cpuFraction: Double {
        min((cpu_pct ?? 0) / 100, 1.0)
    }

    // Clean \r artefacts from tqdm / progress bars
    var cleanLastLines: [String] {
        (last_lines ?? []).compactMap { line -> String? in
            let cleaned = line.components(separatedBy: "\r").last?
                .trimmingCharacters(in: .whitespaces) ?? ""
            return cleaned.isEmpty ? nil : cleaned
        }
    }

    func withLogLines(_ lines: [String]) -> ProcessInfo {
        ProcessInfo(pid: pid, name: name, cmd: cmd, running: running,
                    elapsed: elapsed, cpu_pct: cpu_pct, mem_mb: mem_mb,
                    last_lines: last_lines, log_lines: lines,
                    log: log, exit_code: exit_code)
    }

    // The status file claims "running" but the pid is gone (killed, or mon
    // itself died before writing the final status).
    func markedFinished() -> ProcessInfo {
        ProcessInfo(pid: pid, name: name, cmd: cmd, running: false,
                    elapsed: elapsed, cpu_pct: nil, mem_mb: nil,
                    last_lines: last_lines, log_lines: log_lines,
                    log: log, exit_code: exit_code)
    }
}
