#!/bin/bash
set -e

echo "[TC05] Crash consistency – Kill during backup"

DATASET="dataset"
SNAP_DIR="store/snapshots"


########################################
# Record snapshot list BEFORE
########################################
BEFORE_SNAPS=($(ls "$SNAP_DIR" | grep -E '^[0-9]+$' | sort))
echo "[INFO] Snapshots before backup: ${#BEFORE_SNAPS[@]}"

########################################
# Start backup in background
########################################
echo "[ATTACK] Starting backup and killing it mid-way"

py cli.py backup "$DATASET" --label "crash-test" &
BACKUP_PID=$!

# Give backup some time to start
sleep 1

# Kill backup process
kill -9 "$BACKUP_PID" || true
echo "[ATTACK] Backup process killed"

sleep 1

########################################
# Check snapshot list AFTER crash
########################################
AFTER_SNAPS=($(ls "$SNAP_DIR" | grep -E '^[0-9]+$' | sort))
echo "[INFO] Snapshots after crash: ${#AFTER_SNAPS[@]}"

if [ ${#AFTER_SNAPS[@]} -ne ${#BEFORE_SNAPS[@]} ]; then
  echo "[FAIL] Snapshot count changed after crash"
  exit 1
else
  echo "[PASS] No partial snapshot created"
fi

########################################
# Verify latest snapshot still OK
########################################
LATEST=${BEFORE_SNAPS[-1]}

echo "[INFO] Verifying latest snapshot: $LATEST"
py cli.py verify "$LATEST"
echo "[PASS] Existing snapshot still valid"

########################################
# Run backup again (should succeed)
########################################
echo "[INFO] Running backup again after crash"
py cli.py backup "$DATASET" --label "crash-recovery"

NEW_SNAPS=($(ls "$SNAP_DIR" | grep -E '^[0-9]+$' | sort))

if [ ${#NEW_SNAPS[@]} -ne $((${#BEFORE_SNAPS[@]} + 1)) ]; then
  echo "[FAIL] Backup did not succeed after crash"
  exit 1
else
  echo "[PASS] Backup succeeded after crash"
fi

echo "[TC05] DONE – crash consistency verified"
