#!/bin/bash
set -e

echo "[TC06] RBAC – Policy enforcement"

########################################
# Ensure test users exist
########################################
ensure_user() {
  if ! id "$1" &>/dev/null; then
    echo "[SETUP] Creating user $1"
    sudo useradd -m "$1"
  else
    echo "[SETUP] User $1 already exists"
  fi
}

ensure_user operator1
ensure_user auditor1
ensure_user eviluser

########################################
# Operator: init should be DENY
########################################
echo "[TEST] operator1 runs init (expect DENY)"
sudo -u operator1 python3 cli.py init && {
  echo "[FAIL] operator1 init allowed"
  exit 1
} || echo "[PASS] operator1 init denied"

########################################
# Auditor: restore should be DENY
########################################
SNAP=$(ls store/snapshots | sort | tail -n 1)

echo "[TEST] auditor1 runs restore (expect DENY)"
sudo -u auditor1 python3 cli.py restore "$SNAP" out && {
  echo "[FAIL] auditor1 restore allowed"
  exit 1
} || echo "[PASS] auditor1 restore denied"

########################################
# Unknown user: any command should be DENY
########################################
echo "[TEST] eviluser (not in policy) runs list-snapshots (expect DENY)"
sudo -u eviluser python3 cli.py list-snapshots && {
  echo "[FAIL] eviluser command allowed"
  exit 1
} || echo "[PASS] eviluser denied as expected"

echo "[TC06] DONE"
