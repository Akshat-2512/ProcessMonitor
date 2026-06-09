export const command = "python3 ~/.process_monitor/read_status.py 2>/dev/null || echo '[]'"

export const refreshFrequency = 3000

export const className = `
  * { box-sizing: border-box; margin: 0; padding: 0; }

  position: fixed;
  top: 24px;
  right: 24px;
  width: 380px;
  z-index: 1;
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;

  .card {
    background: rgba(16, 16, 20, 0.82);
    backdrop-filter: blur(28px) saturate(1.4);
    -webkit-backdrop-filter: blur(28px) saturate(1.4);
    border: 1px solid rgba(255, 255, 255, 0.07);
    border-radius: 18px;
    overflow: hidden;
    box-shadow:
      0 0 0 0.5px rgba(0,0,0,0.6),
      0 8px 40px rgba(0,0,0,0.5),
      0 2px 8px rgba(0,0,0,0.4);
  }

  .header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 13px 18px 11px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.055);
  }

  .header-title {
    font-size: 10px;
    font-weight: 600;
    letter-spacing: 1.3px;
    color: rgba(255, 255, 255, 0.28);
    text-transform: uppercase;
  }

  .header-count {
    font-size: 10px;
    font-weight: 500;
    letter-spacing: 0.4px;
    color: rgba(255, 255, 255, 0.2);
  }

  .empty {
    padding: 28px 18px;
    font-size: 12px;
    color: rgba(255, 255, 255, 0.18);
    text-align: center;
    letter-spacing: 0.2px;
  }

  /* ── Running process block ── */
  .proc {
    padding: 14px 18px 16px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.05);
  }

  .proc:last-child { border-bottom: none; }

  .proc-top {
    display: flex;
    align-items: center;
    gap: 9px;
    margin-bottom: 5px;
  }

  .dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    flex-shrink: 0;
  }

  .dot-running {
    background: #30D158;
    box-shadow: 0 0 6px rgba(48, 209, 88, 0.8);
    animation: glow 2s ease-in-out infinite;
  }

  .dot-done   { background: #3A3A3C; }
  .dot-failed { background: #FF453A; box-shadow: 0 0 6px rgba(255, 69, 58, 0.6); }

  @keyframes glow {
    0%, 100% { opacity: 1;   box-shadow: 0 0 5px rgba(48,209,88,0.7); }
    50%       { opacity: 0.55; box-shadow: 0 0 12px rgba(48,209,88,0.9); }
  }

  .proc-name {
    font-size: 14px;
    font-weight: 600;
    color: rgba(255, 255, 255, 0.88);
    flex: 1;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .proc-elapsed {
    font-size: 11px;
    font-family: 'Menlo', 'SF Mono', monospace;
    color: rgba(255, 255, 255, 0.28);
  }

  .proc-cmd {
    font-size: 10px;
    font-family: 'Menlo', 'SF Mono', monospace;
    color: rgba(255, 255, 255, 0.25);
    margin-bottom: 12px;
    margin-left: 17px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  /* ── Stat bars ── */
  .stats {
    display: flex;
    gap: 14px;
    margin-bottom: 12px;
    margin-left: 17px;
  }

  .stat { flex: 1; }

  .stat-header {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    margin-bottom: 5px;
  }

  .stat-label {
    font-size: 9px;
    font-weight: 600;
    letter-spacing: 0.9px;
    color: rgba(255, 255, 255, 0.22);
    text-transform: uppercase;
  }

  .stat-value {
    font-size: 11px;
    font-family: 'Menlo', monospace;
    font-weight: 500;
    color: rgba(255, 255, 255, 0.65);
  }

  .bar-track {
    height: 3px;
    background: rgba(255, 255, 255, 0.07);
    border-radius: 2px;
    overflow: hidden;
  }

  .bar-fill {
    height: 100%;
    border-radius: 2px;
    transition: width 0.6s cubic-bezier(0.4, 0, 0.2, 1);
  }

  .bar-cpu { background: linear-gradient(90deg, #0A84FF, #40C8FF); }
  .bar-mem { background: linear-gradient(90deg, #BF5AF2, #DA8FFF); }

  /* ── Output block ── */
  .output {
    background: rgba(0, 0, 0, 0.28);
    border: 1px solid rgba(255, 255, 255, 0.05);
    border-radius: 9px;
    padding: 9px 11px;
    margin-left: 17px;
  }

  .output-label {
    font-size: 9px;
    font-weight: 600;
    letter-spacing: 0.9px;
    color: rgba(255, 255, 255, 0.18);
    text-transform: uppercase;
    margin-bottom: 6px;
  }

  .output-line {
    font-family: 'Menlo', 'SF Mono', monospace;
    font-size: 10px;
    color: rgba(255, 255, 255, 0.35);
    line-height: 1.65;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .output-line.latest {
    color: rgba(255, 255, 255, 0.58);
  }

  /* ── Finished row ── */
  .done-section {
    border-top: 1px solid rgba(255, 255, 255, 0.05);
  }

  .done-row {
    display: flex;
    align-items: center;
    gap: 9px;
    padding: 9px 18px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.04);
  }

  .done-row:last-child { border-bottom: none; }

  .done-name {
    font-size: 12px;
    font-weight: 500;
    color: rgba(255, 255, 255, 0.3);
    flex: 1;
  }

  .done-meta {
    font-size: 10px;
    font-family: 'Menlo', monospace;
    color: rgba(255, 255, 255, 0.18);
  }

  .badge {
    font-size: 9px;
    font-weight: 600;
    padding: 2px 6px;
    border-radius: 4px;
    letter-spacing: 0.5px;
    text-transform: uppercase;
  }

  .badge-ok     { background: rgba(48, 209, 88, 0.15);  color: #30D158; }
  .badge-failed { background: rgba(255, 69, 58, 0.15);  color: #FF453A; }
`

export default function render({ output }) {
  let procs = []
  try { procs = JSON.parse(output || "[]") } catch (e) {}

  const running = procs.filter(p => p.running)
  const done    = procs.filter(p => !p.running)

  function fmtMem(mb) {
    return mb >= 1024 ? `${(mb / 1024).toFixed(2)} GB` : `${mb.toFixed(0)} MB`
  }

  function memPct(mb) {
    return Math.min(100, (mb / (16 * 1024)) * 100)
  }

  return (
    <div className="card">
      <div className="header">
        <span className="header-title">Processes</span>
        <span className="header-count">
          {running.length > 0 ? `${running.length} running` : "idle"}
        </span>
      </div>

      {procs.length === 0 && (
        <div className="empty">No monitored processes</div>
      )}

      {running.map((p, i) => (
        <div key={i} className="proc">
          <div className="proc-top">
            <div className="dot dot-running" />
            <span className="proc-name">{p.name}</span>
            <span className="proc-elapsed">{p.elapsed}</span>
          </div>

          {p.cmd && (
            <div className="proc-cmd">
              {p.cmd.length > 52 ? p.cmd.slice(0, 52) + "…" : p.cmd}
            </div>
          )}

          <div className="stats">
            {p.cpu_pct != null && (
              <div className="stat">
                <div className="stat-header">
                  <span className="stat-label">CPU</span>
                  <span className="stat-value">{p.cpu_pct.toFixed(1)}%</span>
                </div>
                <div className="bar-track">
                  <div className="bar-fill bar-cpu"
                    style={{ width: `${Math.min(p.cpu_pct, 100)}%` }} />
                </div>
              </div>
            )}
            {p.mem_mb != null && (
              <div className="stat">
                <div className="stat-header">
                  <span className="stat-label">MEM</span>
                  <span className="stat-value">{fmtMem(p.mem_mb)}</span>
                </div>
                <div className="bar-track">
                  <div className="bar-fill bar-mem"
                    style={{ width: `${memPct(p.mem_mb)}%` }} />
                </div>
              </div>
            )}
          </div>

          {p.last_lines && p.last_lines.length > 0 && (
            <div className="output">
              <div className="output-label">Output</div>
              {p.last_lines.map((l, j) => (
                <div key={j}
                  className={`output-line${j === p.last_lines.length - 1 ? " latest" : ""}`}>
                  {l}
                </div>
              ))}
            </div>
          )}
        </div>
      ))}

      {done.length > 0 && (
        <div className="done-section">
          {done.map((p, i) => {
            const ok = (p.exit_code || 0) === 0
            return (
              <div key={i} className="done-row">
                <div className={`dot ${ok ? "dot-done" : "dot-failed"}`} />
                <span className="done-name">{p.name}</span>
                <span className={`badge ${ok ? "badge-ok" : "badge-failed"}`}>
                  {ok ? "done" : `exit ${p.exit_code}`}
                </span>
                <span className="done-meta">{p.elapsed}</span>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
