#!/bin/bash
set -e

CLI="py cli.py"
STORE="store"
DATASET="tests/dataset"

echo "[TC02] Integrity – Chunk corruption detection (hierarchical chunks)"

# Cleanup
rm -rf $STORE

# Init & backup
$CLI init
$CLI backup $DATASET --label "chunk-corruption-test"

# Get snapshot id
SID=$(ls $STORE/snapshots | head -n1 | sed 's/.json//')

# Find ONE real chunk file (recursive)
CHUNK_PATH=$(find $STORE/chunks -type f | head -n1)

if [ -z "$CHUNK_PATH" ]; then
  echo "[FAIL] No chunk file found"
  exit 1
fi

echo "[INFO] Corrupting chunk file: $CHUNK_PATH"

# Modify exactly 1 byte
printf '\x00' | dd of="$CHUNK_PATH" bs=1 count=1 conv=notrunc 2>/dev/null

# Verify must fail
if $CLI verify "$SID"; then
  echo "[FAIL] Verify passed but should fail"
  exit 1
else
  echo "[PASS] Verify failed as expected due to chunk corruption"
fi
