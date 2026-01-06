import time
from utils.hashing import sha256
from utils.fs import ensure_dir
from pathlib import Path
class Audit:
    def __init__(self, path):
        self.path = path
        ensure_dir(path.parent)   # ✅ TẠO store/ NẾU CHƯA CÓ

        self.last = "0" * 64
        if path.exists() and path.stat().st_size > 0:
            self.last = path.read_text().splitlines()[-1].split()[0]

    def log(self, user, cmd, args, status):
        ts = int(time.time() * 1000)
        args_h = sha256(args.encode())
        body = f"{self.last} {ts} {user} {cmd} {args_h} {status}"
        entry = sha256(body.encode())
        with open(self.path, "a") as f:
            f.write(f"{entry} {body}\n")
        self.last = entry


def audit_verify(path: Path):
    """
    Verify integrity of audit log using hash chaining.
    Return head hash if OK, raise Exception if tampered.
    """
    if not path.exists():
        raise RuntimeError("Audit log not found")

    last = "0" * 64

    with open(path, "r", encoding="utf-8") as f:
        for lineno, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue

            entry, prev, ts, user, cmd, args_h, status = line.split()

            if prev != last:
                raise RuntimeError(f"AUDIT TAMPER DETECTED at line {lineno}")

            body = f"{prev} {ts} {user} {cmd} {args_h} {status}"
            calc = sha256(body.encode())

            if calc != entry:
                raise RuntimeError(f"AUDIT HASH MISMATCH at line {lineno}")

            last = entry

    return last