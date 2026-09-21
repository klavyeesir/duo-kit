#!/usr/bin/env bash
# Entrypoint for the DuoLint Docker action.
# GitHub exposes each action input as INPUT_<NAME>, uppercased with dashes
# replaced by underscores.
set -uo pipefail

SCAN_PATH="${INPUT_PATH:-.}"
FORMAT="${INPUT_FORMAT:-github}"
SARIF_FILE="${INPUT_SARIF_FILE:-duolint.sarif}"
FAIL_ON_FINDINGS="${INPUT_FAIL_ON_FINDINGS:-true}"

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
