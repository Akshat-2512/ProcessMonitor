import json
import os
import time
from datetime import timedelta
from pathlib import Path

try:
    import torch
    _TORCH = True
except ImportError:
    _TORCH = False


class TrainingStatusWriter:
    """
    Writes training state to ~/.training_status.json every N steps
    so the SwiftBar widget can display live progress.

    Usage:
        writer = TrainingStatusWriter(total_epochs=50, total_steps=len(train_loader))

        for epoch in range(50):
            for step, (x, y) in enumerate(train_loader):
                ...
                writer.update(epoch+1, step+1, loss=loss.item(), accuracy=acc, lr=scheduler.get_last_lr()[0])

        writer.done()
    """

    def __init__(
        self,
        total_epochs: int,
        total_steps: int = None,
        status_file: str = "~/.training_status.json",
        write_every_n_steps: int = 10,
    ):
        self.total_epochs = total_epochs
        self.total_steps = total_steps
        self.status_file = Path(status_file).expanduser()
        self.write_every_n_steps = write_every_n_steps
        self.pid = os.getpid()
        self.start_time = time.time()
        self._step_counter = 0

    def update(
        self,
        epoch: int,
        step: int = None,
        loss: float = None,
        accuracy: float = None,
        lr: float = None,
        force: bool = False,
    ):
        self._step_counter += 1
        if not force and self._step_counter % self.write_every_n_steps != 0:
            return

        elapsed_sec = time.time() - self.start_time
        elapsed_str = str(timedelta(seconds=int(elapsed_sec)))

        if epoch > 0 and elapsed_sec > 0:
            secs_per_epoch = elapsed_sec / epoch
            remaining = (self.total_epochs - epoch) * secs_per_epoch
            eta = str(timedelta(seconds=int(remaining)))
        else:
            eta = "calculating..."

        status = {
            "pid": self.pid,
            "epoch": epoch,
            "total_epochs": self.total_epochs,
            "elapsed": elapsed_str,
            "eta": eta,
            "done": False,
        }

        if step is not None:
            status["step"] = step
            status["total_steps"] = self.total_steps

        if loss is not None:
            status["loss"] = round(float(loss), 6)

        if accuracy is not None:
            status["accuracy"] = round(float(accuracy), 4)

        if lr is not None:
            status["lr"] = float(lr)

        if _TORCH and torch.cuda.is_available():
            status["gpu_memory_mb"] = round(torch.cuda.memory_allocated() / 1024 ** 2, 1)
            status["gpu_total_mb"] = round(
                torch.cuda.get_device_properties(0).total_memory / 1024 ** 2, 1
            )

        self.status_file.write_text(json.dumps(status, indent=2))

    def done(self):
        if self.status_file.exists():
            try:
                d = json.loads(self.status_file.read_text())
            except Exception:
                d = {}
            d["done"] = True
            d["pid"] = -1
            d["eta"] = "Done!"
            elapsed_sec = time.time() - self.start_time
            d["elapsed"] = str(timedelta(seconds=int(elapsed_sec)))
            self.status_file.write_text(json.dumps(d, indent=2))
