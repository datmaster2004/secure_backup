#!/bin/bash
set -e

echo "[TC03] Integrity – Manifest & Metadata corruption detection"

SNAPSHOT_ID=$(ls store/snapshots | sort | tail -n 1)

if [ -z "$SNAPSHOT_ID" ]; then
  echo "[ERROR] No snapshot found"
  exit 1
fi

export SNAPSHOT_ID
SNAP_DIR="store/snapshots/$SNAPSHOT_ID"

MANIFEST="$SNAP_DIR/manifest.json"
META="$SNAP_DIR/meta.json"

echo "[INFO] Using snapshot: $SNAPSHOT_ID"

# Backup
cp "$MANIFEST" "$MANIFEST.bak"
cp "$META" "$META.bak"

########################################
# 1. Corrupt MANIFEST
########################################
echo "[INFO] Corrupting manifest.json (flip 1 hex char)"

py - << 'EOF'
import json, os

sid = os.environ["SNAPSHOT_ID"]
path = f"store/snapshots/{sid}/manifest.json"
with open(path, "r") as f:
    data = json.load(f)

k = next(iter(data))
h = data[k][0]

# flip 1 hex char
data[k][0] = ("f" if h[0] != "f" else "e") + h[1:]

with open(path, "w") as f:
    json.dump(data, f, indent=2)
EOF

echo "[INFO] Running verify (expect FAIL due to manifest corruption)"
if py cli.py verify "$SNAPSHOT_ID"; then
    echo "[FAIL] Verify passed but should fail (manifest corrupted)"
    exit 1
else
    echo "[PASS] Verify failed as expected (manifest corrupted)"
fi

########################################
# Restore MANIFEST
########################################
mv "$MANIFEST.bak" "$MANIFEST"

########################################
# 2. Corrupt METADATA
########################################
echo "[INFO] Corrupting meta.json (modify root hash)"

py - << 'EOF'
import json, os

sid = os.environ["SNAPSHOT_ID"]
path = f"store/snapshots/{sid}/meta.json"
with open(path, "r") as f:
    meta = json.load(f)

meta["root"] = "deadbeef" * 8

with open(path, "w") as f:
    json.dump(meta, f, indent=2)
EOF

echo "[INFO] Running verify (expect FAIL due to metadata corruption)"
if py cli.py verify "$SNAPSHOT_ID"; then
    echo "[FAIL] Verify passed but should fail (metadata corrupted)"
    exit 1
else
    echo "[PASS] Verify failed as expected (metadata corrupted)"
fi

########################################
# Restore METADATA
########################################
mv "$META.bak" "$META"

echo "[TC03] DONE – files restored"
