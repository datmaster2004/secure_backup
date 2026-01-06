#!/bin/bash
set -e
source tests/common.sh

echo "TC01: Restore after source deletion"

$CLI init
$CLI backup $DATASET --label v1

SID=$(get_first_snapshot)

cp -r $DATASET tests/dataset_backup
rm -rf $DATASET

$CLI restore $SID $OUT
diff -r $OUT tests/dataset_backup || FAIL "Restore mismatch"

PASS "Restore correct after deleting source"
