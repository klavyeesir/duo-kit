#!/usr/bin/env bash
set -euo pipefail
BIN=.build/debug/DuoLint

for f in Fixtures/bad/*.swift; do
  rule=$(basename "$f" .swift)
  if "$BIN" "$f" > /tmp/out.txt; then
    echo "FAIL: $f exited 0 (expected findings)"; exit 1
  fi
  grep -q "\[$rule\]" /tmp/out.txt || { echo "FAIL: $f did not report [$rule]"; cat /tmp/out.txt; exit 1; }
  echo "ok   bad/$(basename "$f")"
done

for f in Fixtures/clean/*.swift; do
  if ! "$BIN" "$f" > /tmp/out.txt; then
    echo "FAIL: $f was flagged"; cat /tmp/out.txt; exit 1
  fi
  echo "ok   clean/$(basename "$f")"
done

echo "All fixture tests passed"
