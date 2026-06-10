import SwiftUI

// MARK: - Main popover view

struct MainView: View {
    var store: ProcessStore

    @State private var filter: Filter = .running
    @State private var expandedPid: Int? = nil

    enum Filter: String, CaseIterable {
        case running = "Running", done = "Done", all = "All"
    }

    var visible: [ProcessInfo] {
        switch filter {
        case .running: return store.running
        case .done:    return Array(store.done.prefix(8))
        case .all:     return store.processes
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.4)

            if visible.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    if filter == .all {
                        let runningProcs = visible.filter(\.running)
                        let doneProcs    = visible.filter { !$0.running }
                        if !runningProcs.isEmpty {
                            SectionHeader(title: "Running")
                            ForEach(runningProcs) { proc in
                                RunningRow(proc: proc, expandedPid: $expandedPid,
                                           onKill: { store.kill(pid: proc.pid) })
                                Divider().opacity(0.2).padding(.horizontal, 14)
                            }
                        }
                        if !doneProcs.isEmpty {
                            SectionHeader(title: "Recent")
                            ForEach(doneProcs) { proc in
                                DoneRow(proc: proc, expandedPid: $expandedPid)
                                Divider().opacity(0.2).padding(.horizontal, 14)
                            }
                        }
                    } else {
                        ForEach(visible) { proc in
                            if proc.running {
                                RunningRow(proc: proc, expandedPid: $expandedPid,
                                           onKill: { store.kill(pid: proc.pid) })
                            } else {
                                DoneRow(proc: proc, expandedPid: $expandedPid)
                            }
                            Divider().opacity(0.2).padding(.horizontal, 14)
                        }
                    }
                }
            }

            Divider().opacity(0.4)
            footer
        }
        .frame(width: 520)
        .background(.ultraThinMaterial)
        .overlay {
            if let pid = expandedPid,
               let proc = store.processes.first(where: { $0.pid == pid }) {
                LogOverlay(proc: proc) { expandedPid = nil }
            }
        }
    }

    // ── Header ──────────────────────────────────────────────────
    var header: some View {
        HStack(spacing: 8) {
            Text(store.running.isEmpty ? "Idle" : "\(store.running.count) Running")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)

            Spacer()

            HStack(spacing: 4) {
                ForEach(Filter.allCases, id: \.self) { f in
                    FilterTab(
                        label: tabLabel(f),
                        active: filter == f
                    ) { filter = f }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // ── Footer ──────────────────────────────────────────────────
    var footer: some View {
        HStack {
            Button(action: { store.load() }) {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()

            Button(action: { NSApp.terminate(nil) }) {
                Label("Quit", systemImage: "power")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    var emptyState: some View {
        Text(filter == .running ? "No running processes" :
             filter == .done    ? "No finished processes" :
             "No processes — run mon <command>")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .padding(28)
    }

    func tabLabel(_ f: Filter) -> String {
        switch f {
        case .running: return store.running.isEmpty ? "Running" : "Running (\(store.running.count))"
        case .done:    return store.done.isEmpty    ? "Done"    : "Done (\(store.done.count))"
        case .all:     return "All"
        }
    }
}

// MARK: - Filter tab button

struct FilterTab: View {
    let label: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: active ? .semibold : .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(active ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(active ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(active ? Color.accentColor : Color.primary.opacity(0.55))
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
            .tracking(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }
}

// MARK: - Running process row

struct RunningRow: View {
    let proc: ProcessInfo
    @Binding var expandedPid: Int?
    var onKill: () -> Void = {}

    @State private var confirmingKill = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top row: dot + name + elapsed + kill
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 7, height: 7)
                    .shadow(color: .green.opacity(0.8), radius: 3)

                Text(proc.name)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)

                Spacer()

                Text(proc.elapsed ?? "")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)

                KillButton(confirming: $confirmingKill, onKill: onKill)
            }

            // Command
            if let cmd = proc.cmd {
                Text(cmd)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .padding(.leading, 15)
            }

            // Stats bars
            HStack(spacing: 12) {
                if proc.cpu_pct != nil {
                    StatBar(
                        label: "CPU",
                        value: String(format: "%.1f%%", proc.cpu_pct!),
                        fraction: proc.cpuFraction,
                        color: .blue
                    )
                }
                if proc.mem_mb != nil {
                    StatBar(
                        label: "MEM",
                        value: proc.formattedMem ?? "",
                        fraction: proc.memFraction,
                        color: .purple
                    )
                }
            }
            .padding(.leading, 15)

            // Output preview
            let lines = proc.cleanLastLines
            if !lines.isEmpty {
                OutputPreview(lines: lines, pid: proc.pid, expandedPid: $expandedPid)
                    .padding(.leading, 15)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Kill button (two-step confirm)

struct KillButton: View {
    @Binding var confirming: Bool
    let onKill: () -> Void

    var body: some View {
        Button {
            if confirming {
                onKill()
                confirming = false
            } else {
                confirming = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    confirming = false
                }
            }
        } label: {
            if confirming {
                Text("confirm kill?")
                    .font(.system(size: 9, weight: .semibold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.85))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            } else {
                Image(systemName: "stop.fill")
                    .font(.system(size: 9))
                    .padding(5)
                    .background(Color.red.opacity(0.12))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
        .buttonStyle(.plain)
        .help("Kill this process")
    }
}

// MARK: - Done process row

struct DoneRow: View {
    let proc: ProcessInfo
    @Binding var expandedPid: Int?

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(proc.succeeded ? Color.secondary : Color.red)
                .frame(width: 7, height: 7)

            Text(proc.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if let cmd = proc.cmd {
                Text(cmd)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.quaternary)
                    .lineLimit(1)
                    .frame(maxWidth: 100)
            }

            Spacer()

            Text(proc.elapsed ?? "")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.quaternary)

            Text(proc.succeeded ? "done" : "exit \(proc.exit_code ?? -1)")
                .font(.system(size: 9, weight: .semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(proc.succeeded
                    ? Color.green.opacity(0.15)
                    : Color.red.opacity(0.15))
                .foregroundStyle(proc.succeeded ? .green : .red)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            if proc.log_lines?.isEmpty == false {
                expandedPid = proc.pid
            }
        }
    }
}

// MARK: - Stat bar

struct StatBar: View {
    let label: String
    let value: String
    let fraction: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .tracking(0.8)
                    .textCase(.uppercase)
                Spacer()
                Text(value)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.primary.opacity(0.07))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * fraction)
                        .animation(.easeInOut(duration: 0.5), value: fraction)
                }
            }
            .frame(height: 3)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Output preview

struct OutputPreview: View {
    let lines: [String]
    let pid: Int
    @Binding var expandedPid: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("OUTPUT")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.quaternary)
                    .tracking(0.8)
                Spacer()
                Text("double-click to expand")
                    .font(.system(size: 8))
                    .foregroundStyle(.quaternary)
            }
            .padding(.bottom, 4)

            ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                Text(line)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(i == lines.count - 1
                        ? Color.primary.opacity(0.65)
                        : Color.primary.opacity(0.3))
                    .lineLimit(1)
            }
        }
        .padding(9)
        .background(Color.primary.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { expandedPid = pid }
    }
}

// MARK: - Log overlay

struct LogOverlay: View {
    let proc: ProcessInfo
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(proc.name)
                        .font(.system(size: 12, weight: .semibold))
                    Text("PID \(proc.pid)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("✕  Close", action: onClose)
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider().opacity(0.4)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array((proc.log_lines ?? []).enumerated()), id: \.offset) { i, line in
                            Text(line)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(i == (proc.log_lines?.count ?? 0) - 1
                                    ? Color.primary.opacity(0.75)
                                    : Color.primary.opacity(0.4))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 1)
                                .id(i)
                        }
                    }
                    .padding(12)
                }
                .onAppear {
                    if let last = proc.log_lines?.indices.last {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThickMaterial)
    }
}
