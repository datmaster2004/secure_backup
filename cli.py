import sys
from pathlib import Path
from storage.store import Store
from storage.wal import WAL
from core.chunker import chunk_file
from core.manifest import build_manifest
from core.merkle import merkle_root
from core.resrote import restore_snapshot
from security.user import get_user
from security.policy import Policy
from security.audit import Audit
from security.audit import audit_verify
from utils.hashing import sha256

def main():
    cmd = sys.argv[1]
    args = " ".join(sys.argv[2:])
    user = get_user()
 
    policy = Policy("policy.yaml")
    audit = Audit(Path("store/audit.log"))
    if not policy.allowed(user, cmd):
        audit.log(user, cmd, args, "DENY")
        print(f"DENY: user '{user}' is not allowed to run '{cmd}'")
        return

    store = Store("store")
    wal = WAL("store/wal.log")

    if cmd == "init":
        store.init()
        audit.log(user, cmd, args, "OK")

    elif cmd == "backup":
        src = Path(sys.argv[2])
        label = sys.argv[4]
        sid = str(int(__import__("time").time()))
        wal.append(f"BEGIN {sid}")

        files = {}
        for f in src.rglob("*"):
            if f.is_file():
                chunks = []
                for data, h in chunk_file(f):
                    store.save_chunk(h, data)
                    chunks.append(h)
                files[str(f.relative_to(src))] = chunks

        manifest = build_manifest(files)
        leaves = [sha256((k + ":" + "".join(v)).encode()) for k, v in manifest.items()]
        root = merkle_root(leaves)
        prev = store.get_latest_snapshot()
        prev_root = prev["root"] if prev else ""
        store.save_manifest(sid, manifest)
        store.save_metadata(sid, {"id": sid, "label": label, "root": root, "prev_root": prev_root})
        wal.append(f"COMMIT {sid} {root}")
        audit.log(user, cmd, args, "OK")

    elif cmd == "list-snapshots":
        for s in store.list_snapshots():
            print(s)
        audit.log(user, cmd, args, "OK")
    elif cmd == "verify":
        sid = sys.argv[2]
        meta = store.load_metadata(sid)

        from storage.rollback import detect_rollback
        detect_rollback(store, wal)

        from core.verify import verify_snapshot
        verify_snapshot(store, meta)
        audit.log(user, cmd, args, "OK")
        print("VERIFY OK")

    elif cmd == "restore":
        sid = sys.argv[2]
        out = sys.argv[3]

        meta = store.load_metadata(sid)
        restore_snapshot(store, meta, out)

        audit.log(user, cmd, args, "OK")
        print("RESTORE OK")

    elif cmd == "audit-verify":
        
        head = audit_verify(Path("store/audit.log"))
        audit.log(user, cmd, args, "OK")
        print("AUDIT OK, HEAD =", head)
if __name__ == "__main__":
    main()
