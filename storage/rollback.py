class RollbackDetected(Exception):
    pass


def detect_rollback(store, wal):
    """
    Detect rollback using append-only roots log (WAL).
    """
    latest = store.get_latest_snapshot()
    if not latest:
        return
    print(f"[DEBUG] latest snapshot: {latest}")
    wal_root = wal.last_committed_root()
    if wal_root is None:
        return
    print(f"[DEBUG] latest root: {latest['root']}, wal root: {wal_root}")
    if latest["root"] != wal_root:
        raise RollbackDetected(
            "ROLLBACK DETECTED: snapshot history does not match WAL history"
        )
