from utils.hashing import sha256
from utils.encoding import canonical_json
from core.merkle import merkle_root

def verify_snapshot(store, snapshot):
    manifest = store.load_manifest(snapshot["id"])

    leaves = []
    for path in sorted(manifest.keys()):
        chunks = manifest[path]
        entry = path + ":" + "".join(chunks)
        leaves.append(sha256(entry.encode()))

        # verify từng chunk tồn tại
        for h in chunks:
            store.load_chunk(h)  # nếu thiếu → exception

    calc_root = merkle_root(leaves)
    if calc_root != snapshot["root"]:
        raise Exception("VERIFY FAIL: Merkle root mismatch")
