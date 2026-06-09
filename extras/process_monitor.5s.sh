#!/bin/bash
# SwiftBar process monitor

python3 - <<'PYEOF'
import json, sys, os
from pathlib import Path

mon_dir = Path.home() / ".process_monitor"

def line(text, **kw):
    if not kw:
        return text
    attrs = " ".join(f"{k}={v}" for k, v in kw.items())
    return f"{text} | {attrs}"

def sep():
    print("---")

if not mon_dir.exists():
    print(line("● No Processes", color="#666666", size=13))
    sys.exit(0)

procs = []
for f in sorted(mon_dir.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True):
    try:
        d = json.loads(f.read_text())
        d["_file"] = str(f)
        procs.append(d)
    except Exception:
        pass

if not procs:
    print(line("● No Processes", color="#666666", size=13))
    sys.exit(0)

running = [p for p in procs if p.get("running")]
done    = [p for p in procs if not p.get("running")]

# ── Menu bar title ───────────────────────────────────────────────────────────
if len(running) == 1:
    p = running[0]
    parts = [p["name"]]
    if p.get("cpu_pct") is not None:
        parts.append(f"{p['cpu_pct']:.0f}% CPU")
    if p.get("mem_mb") is not None:
        mb = p["mem_mb"]
        parts.append(f"{mb/1024:.1f} GB" if mb >= 1024 else f"{mb:.0f} MB")
    if p.get("elapsed"):
        parts.append(p["elapsed"])
    print(line("● " + "  ·  ".join(parts), color="#30D158", size=12))
elif len(running) > 1:
    print(line(f"● {len(running)} running", color="#30D158", size=12))
elif any(p.get("exit_code", 0) != 0 for p in done):
    failed = next(p for p in done if p.get("exit_code", 0) != 0)
    print(line(f"● {failed['name']} failed", color="#FF453A", size=12))
elif done:
    print(line(f"● {done[0]['name']} done", color="#636366", size=12))
else:
    print(line("● No Processes", color="#666666", size=13))
    sys.exit(0)

sep()

# ── Running processes ────────────────────────────────────────────────────────
if running:
    print(line("RUNNING", color="#888888", size=10))
    sep()
    for p in running:
        # Process name + elapsed
        print(line(f"  {p['name']}", size=14, color="#F2F2F7"))
        cmd = p.get("cmd", "")
        if cmd:
            display_cmd = (cmd[:65] + "…") if len(cmd) > 65 else cmd
            print(line(f"  {display_cmd}", size=11, color="#8E8E93", trim="false"))
        print(line(f"  PID {p['pid']}  ·  running for {p.get('elapsed','—')}", size=11, color="#636366"))
        sep()

        # Stats row
        stats = []
        if p.get("cpu_pct") is not None:
            stats.append(("CPU", f"{p['cpu_pct']:.1f}%"))
        if p.get("mem_mb") is not None:
            mb = p["mem_mb"]
            stats.append(("MEM", f"{mb/1024:.2f} GB" if mb >= 1024 else f"{mb:.0f} MB"))
        for label, val in stats:
            print(line(f"  {label}  {val}", size=12, font="Menlo", color="#EBEBF5"))
        if stats:
            sep()

        # Log output section
        last = p.get("last_lines", [])
        if last:
            print(line("  OUTPUT", size=10, color="#888888"))
            for l in last:
                clean = l[:90]
                print(line(f"  {clean}", size=11, font="Menlo", color="#98989D", trim="false"))
            sep()

        # Actions
        log = p.get("log", "")
        if log and os.path.exists(log):
            print(line("  📋  View Full Log", size=12, color="#0A84FF",
                       bash="open", param1=log, terminal="false"))
        print("---")

# ── Finished / crashed ───────────────────────────────────────────────────────
if done:
    print(line("RECENT", color="#888888", size=10))
    sep()
    for p in done:
        code = p.get("exit_code", 0)
        icon  = "✓" if code == 0 else "✕"
        color = "#30D158" if code == 0 else "#FF453A"
        label = "Completed" if code == 0 else f"Failed  (exit {code})"
        print(line(f"  {icon}  {p['name']}  —  {label}", size=13, color=color))
        print(line(f"  Duration: {p.get('elapsed','—')}", size=11, color="#636366"))
        sep()

        last = p.get("last_lines", [])
        if last:
            for l in last:
                clean = l[:90]
                print(line(f"  {clean}", size=11, font="Menlo", color="#636366", trim="false"))
            sep()

        fpath = p["_file"]
        log   = p.get("log", "")
        if log and os.path.exists(log):
            print(line("  📋  View Full Log", size=12, color="#0A84FF",
                       bash="open", param1=log, terminal="false"))
        print(line("  ✕  Dismiss", size=12, color="#636366",
                   bash="rm", param1=fpath, terminal="false", refresh="true"))
        print("---")

# ── Footer ───────────────────────────────────────────────────────────────────
if done:
    clear_cmd = (
        f"import glob,os,json;"
        f"[os.remove(f) for f in glob.glob('{mon_dir}/*.json')"
        f" if not json.loads(open(f).read()).get('running')]"
    )
    print(line("  Clear All Finished", size=11, color="#636366",
               bash="python3", param1="-c", param2=f'"{clear_cmd}"',
               terminal="false", refresh="true"))
PYEOF
