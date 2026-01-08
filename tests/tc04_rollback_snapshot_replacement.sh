#!/bin/bash
set -e

echo "[TC04] Rollback detection – snapshot replacement attack"

########################################
# Ensure data changes between backups
########################################
echo "[SETUP] Modifying dataset to ensure different snapshot roots"
echo "rollback-test $(date)" >> dataset/rollback.txt

py cli.py backup dataset --label "rollback-test"

SNAP_DIR="store/snapshots"
BACKUP_DIR="store/backup"
mkdir -p "$BACKUP_DIR"
SNAPS=($(ls $SNAP_DIR | sort))

if [ ${#SNAPS[@]} -lt 2 ]; then
  echo "[ERROR] Need at least 2 snapshots"
  exit 1
fi

OLD=${SNAPS[-2]}
NEW=${SNAPS[-1]}

echo "[INFO] Old snapshot: $OLD"
echo "[INFO] New snapshot: $NEW"

########################################
# Backup snapshots
########################################
cp -r "$SNAP_DIR/$OLD" "$BACKUP_DIR/$OLD"
cp -r "$SNAP_DIR/$NEW" "$BACKUP_DIR/$NEW"

########################################
# Rollback attack
########################################
echo "[ATTACK] Replacing newest snapshot with older snapshot"
rm -rf "$SNAP_DIR/$NEW"
cp -r "$SNAP_DIR/$OLD" "$SNAP_DIR/$NEW"

########################################
# Verify should FAIL
########################################
echo "[INFO] Running verify (expect ROLLBACK DETECTED)"
if py cli.py verify "$NEW"; then
    echo "[FAIL] Verify passed but rollback was not detected"
    exit 1
else
    echo "[PASS] Rollback detected successfully"
fi

########################################
# Restore state
########################################
rm -rf "$SNAP_DIR/$OLD" "$SNAP_DIR/$NEW"
mv "$BACKUP_DIR/$OLD" "$SNAP_DIR/$OLD"
mv "$BACKUP_DIR/$NEW" "$SNAP_DIR/$NEW"

echo "[TC04] DONE – rollback attack detected and state restored"
