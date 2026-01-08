#!/bin/bash
set -e

echo "[TC07] Audit – audit.log tampering detection"

AUDIT_LOG="store/audit.log"

if [ ! -f "$AUDIT_LOG" ]; then
  echo "[ERROR] audit.log not found"
  exit 1
fi

########################################
# Backup audit.log
########################################
cp "$AUDIT_LOG" "$AUDIT_LOG.bak"

########################################
# 1. Tamper audit.log (modify 1 char)
########################################
echo "[ATTACK] Modifying 1 character in audit.log"

# Replace first character of first line
sed -i '1s/./X/' "$AUDIT_LOG"

########################################
# Run audit-verify (expect FAIL)
########################################
echo "[INFO] Running audit-verify (expect AUDIT CORRUPTED)"
if py cli.py audit-verify; then
    echo "[FAIL] audit-verify passed but audit.log was tampered"
    mv "$AUDIT_LOG.bak" "$AUDIT_LOG"
    exit 1
else
    echo "[PASS] audit-verify failed as expected (AUDIT CORRUPTED)"
fi

########################################
# Restore audit.log
########################################
mv "$AUDIT_LOG.bak" "$AUDIT_LOG"

echo "[TC07] DONE – audit.log restored"
