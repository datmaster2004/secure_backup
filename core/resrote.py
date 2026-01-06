from pathlib import Path
from core.verify import verify_snapshot
from utils.fs import ensure_dir

def restore_snapshot(store, snapshot, out_dir):
    verify_snapshot(store, snapshot)  # BẮT BUỘC

    out_dir = Path(out_dir)
    manifest = store.load_manifest(snapshot["id"])

    for rel_path, chunks in manifest.items():
        target = out_dir / rel_path
        ensure_dir(target.parent)

        with open(target, "wb") as f:
            for h in chunks:
                f.write(store.load_chunk(h))
