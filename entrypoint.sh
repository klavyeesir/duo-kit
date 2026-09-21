#!/usr/bin/env bash
# Entrypoint for the DuoLint Docker action.
#
# Inputs arrive as positional arguments, in the order declared under runs.args
# in action.yml. They are deliberately not read from INPUT_* environment
# variables: GitHub uppercases input names but does not convert dashes, so
# fail-on-findings would arrive as INPUT_FAIL-ON-FINDINGS, which a shell cannot
# expand.
set -uo pipefail

SCAN_PATH="${1:-.}"
FORMAT="${2:-github}"
SARIF_FILE="${3:-duolint.sarif}"
FAIL_ON_FINDINGS="${4:-true}"

if [ "$FORMAT" = "sarif" ]; then
  DuoLint --format sarif "$SCAN_PATH" > "$SARIF_FILE"
else
  DuoLint --format "$FORMAT" "$SCAN_PATH"
fi
code=$?

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "exit-code=$code" >> "$GITHUB_OUTPUT"
fi

# 2 means DuoLint itself could not run; always surface that as a failure.
if [ "$code" -eq 2 ]; then
  echo "::error title=DuoLint::DuoLint could not run (see log above)"
  exit 2
fi

if [ "$code" -eq 1 ] && [ "$FAIL_ON_FINDINGS" = "true" ]; then
  exit 1
fi

exit 0
