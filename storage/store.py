import json
from pathlib import Path
from utils.fs import ensure_dir
from utils.encoding import canonical_json

class Store:
    def __init__(self, root):
        self.root = Path(root)
        self.chunks = self.root / "chunks"
        self.snaps = self.root / "snapshots"

    def init(self):
        ensure_dir(self.chunks)
        ensure_dir(self.snaps)

    def save_chunk(self, h, data):
        path = self.chunks / h[:2]
        ensure_dir(path)
        file = path / h
        if not file.exists():
            file.write_bytes(data)

    def load_chunk(self, h):
        return (self.chunks / h[:2] / h).read_bytes()

    def save_manifest(self, sid, manifest):
        p = self.snaps / sid
        ensure_dir(p)
        (p / "manifest.json").write_bytes(canonical_json(manifest))

    def load_manifest(self, sid):
        return json.loads((self.snaps / sid / "manifest.json").read_text())

    def save_metadata(self, sid, meta):
        (self.snaps / sid / "meta.json").write_text(json.dumps(meta))

    def load_metadata(self, sid):
        return json.loads((self.snaps / sid / "meta.json").read_text())

    def list_snapshots(self):
        return [p.name for p in self.snaps.iterdir() if p.is_dir()]
    def get_latest_snapshot(self):
        snaps = sorted(self.list_snapshots())
        if not snaps:
            return None
        return self.load_metadata(snaps[-1])