from utils.hashing import sha256
from utils.encoding import canonical_json
from core.merkle import merkle_root

def verify_snapshot(store, meta):
    """
    Verify snapshot integrity:
    - chunk content hash
    - manifest consistency
    - merkle root
    """

    manifest = store.load_manifest(meta["id"])

    # 1️⃣ Verify each chunk content
    for path, chunk_hashes in manifest.items():
        for h in chunk_hashes:
            data = store.load_chunk(h)
            actual = sha256(data)
            if actual != h:
                raise Exception(
                    f"CHUNK CORRUPTED: expected {h}, got {actual}"
                )

    # 2️⃣ Recompute Merkle root
    leaves = [
        sha256((path + ":" + "".join(chunks)).encode())
        for path, chunks in manifest.items()
    ]

    root = merkle_root(leaves)

    if root != meta["root"]:
        raise Exception(
            f"MERKLE ROOT MISMATCH: expected {meta['root']}, got {root}"
        )
