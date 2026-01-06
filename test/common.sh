#!/bin/bash

CLI="python3 cli.py"
STORE="store"
DATASET="dataset"
OUT="tests/output"

PASS() { echo "[PASS] $1"; }
FAIL() { echo "[FAIL] $1"; exit 1; }

get_first_snapshot() {
  ls $STORE/snapshots | head -n1 | sed 's/.json//'
}

get_last_snapshot() {
  ls $STORE/snapshots | tail -n1 | sed 's/.json//'
}
