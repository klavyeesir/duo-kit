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

# Klasör tarama
if "$BIN" Fixtures/bad > /dev/null; then
  echo "FAIL: directory scan of Fixtures/bad exited 0"; exit 1
fi
"$BIN" Fixtures/clean > /dev/null || { echo "FAIL: directory scan of Fixtures/clean was flagged"; exit 1; }
echo "ok   directory scan"

# Olmayan yol: araç hatası (exit 2) vermeli
set +e
"$BIN" does-not-exist > /dev/null 2>&1
code=$?
set -e
[ "$code" -eq 2 ] || { echo "FAIL: missing path returned $code, expected 2"; exit 1; }
echo "ok   missing path -> exit 2"

# GitHub annotation formatı
"$BIN" --format github Fixtures/bad/duo-screen-bounds.swift > /tmp/out.txt || true
grep -q "^::warning file=Fixtures/bad/duo-screen-bounds.swift,line=2," /tmp/out.txt \
  || { echo "FAIL: github format output"; cat /tmp/out.txt; exit 1; }
echo "ok   github annotation format"

echo "All fixture tests passed"

# Agent skill kısa kalmalı
lines=$(wc -l < skills/iphone-duo/SKILL.md)
[ "$lines" -le 180 ] || { echo "FAIL: SKILL.md has $lines lines (max 180)"; exit 1; }
echo "ok   SKILL.md size ($lines lines)"

# Referans dosyası da sınırsız büyümesin, yoksa bölme guardrail'i delmenin yolu olur
ref=$(wc -l < skills/iphone-duo/references/duo-api.md)
[ "$ref" -le 200 ] || { echo "FAIL: duo-api.md has $ref lines (max 200)"; exit 1; }
echo "ok   duo-api.md size ($ref lines)"
