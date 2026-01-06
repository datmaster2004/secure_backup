from pathlib import Path

class WAL:
    def __init__(self, path):
        self.path = Path(path)

    def append(self, line):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with open(self.path, "a") as f:
            f.write(line + "\n")

    def recover(self):
        begun = set()
        committed = set()
        if not self.path.exists():
            return set()

        for l in self.path.read_text().splitlines():
            t, sid = l.split()
            if t == "BEGIN":
                begun.add(sid)
            if t == "COMMIT":
                committed.add(sid)

        return begun - committed
    def last_committed_root(self):
        if not self.path.exists():
            return None

        last_root = None
        with open(self.path) as f:
            for line in f:
                line = line.strip()
                if line.startswith("COMMIT"):
                    parts = line.split()
                    if len(parts) == 3:
                        last_root = parts[2]
        return last_root
