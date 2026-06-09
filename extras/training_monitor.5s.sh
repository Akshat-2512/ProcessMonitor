#!/bin/bash

STATUS_FILE="$HOME/.training_status.json"

if [ ! -f "$STATUS_FILE" ]; then
    echo "⚫ No Training"
    exit 0
fi

python3 - <<'EOF'
import json, os, sys
from pathlib import Path

f = Path.home() / ".training_status.json"
try:
    d = json.loads(f.read_text())
except Exception:
    print("⚠️ Bad status file")
    sys.exit(0)

pid     = d.get("pid", -1)
epoch   = d.get("epoch", 0)
total   = d.get("total_epochs", "?")
loss    = d.get("loss")
acc     = d.get("accuracy")
lr      = d.get("lr")
gpu_mb  = d.get("gpu_memory_mb")
gpu_tot = d.get("gpu_total_mb")
eta     = d.get("eta", "")
elapsed = d.get("elapsed", "")
step    = d.get("step")
tsteps  = d.get("total_steps")
done    = d.get("done", False)

# Check if process is still alive
if done:
    alive = False
    status_icon = "✅"
    status_label = "Done"
elif pid > 0:
    alive = os.path.exists(f"/proc/{pid}") or (os.system(f"kill -0 {pid} 2>/dev/null") == 0)
    status_icon = "🟢" if alive else "🔴"
    status_label = "Training" if alive else "Crashed"
else:
    alive = False
    status_icon = "✅"
    status_label = "Done"

# ── Menu bar title ──────────────────────────────────────────────
bar = f"{status_icon} {epoch}/{total}"
if loss is not None:
    bar += f"  loss {loss:.4f}"
if acc is not None:
    bar += f"  acc {acc:.3f}"
print(bar)
print("---")

# ── Dropdown ────────────────────────────────────────────────────
print(f"Status: {status_label}")
print(f"Epoch:  {epoch} / {total}")

if step is not None and tsteps is not None:
    pct = int(step / tsteps * 100)
    bar_w = 20
    filled = int(bar_w * step / tsteps)
    prog = "█" * filled + "░" * (bar_w - filled)
    print(f"Step:   {step}/{tsteps}  [{prog}] {pct}%")

if loss is not None:
    print(f"Loss:   {loss:.6f}")
if acc is not None:
    print(f"Acc:    {acc:.4f}")
if lr is not None:
    print(f"LR:     {lr:.2e}")
if gpu_mb is not None:
    used_pct = int(gpu_mb / gpu_tot * 100) if gpu_tot else 0
    print(f"GPU:    {gpu_mb:.0f} / {gpu_tot:.0f} MB  ({used_pct}%)")
if elapsed:
    print(f"Elapsed: {elapsed}")
if eta:
    print(f"ETA:    {eta}")

print("---")
print(f"Clear status | bash='rm {Path.home() / '.training_status.json'}' terminal=false refresh=true")
EOF
