#!/usr/bin/env bash
# Kullanım: scripts/score.sh <ajanin-urettigi-dosya> <gorev-klasoru>
set -euo pipefail
OUT="${1:?usage: score.sh <output.swift> <task-dir>}"
TASK="${2:?usage: score.sh <output.swift> <task-dir>}"
BIN=.build/debug/DuoLint

[ -f "$OUT" ] || { echo "FAIL: $OUT not found"; exit 1; }

set +e
"$BIN" "$OUT" > /tmp/score.txt
set -e

fails=0
for rule in $(jq -r '.must_not_report[]' "$TASK/expect.json"); do
  if grep -q "\[$rule\]" /tmp/score.txt; then
    echo "  [ ] $rule  still present"
    fails=$((fails + 1))
  else
    echo "  [x] $rule  fixed"
  fi
done

total=$(jq -r '.must_not_report | length' "$TASK/expect.json")
echo "Score: $((total - fails))/$total"
[ "$fails" -eq 0 ]
