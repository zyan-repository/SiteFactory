#!/usr/bin/env bash
# pre-commit-hook.sh - Run ShellCheck on staged shell scripts before commit.
# Install: cp scripts/pre-commit-hook.sh .git/hooks/pre-commit

set -euo pipefail

if ! command -v shellcheck &>/dev/null; then
  echo "WARNING: shellcheck not installed, skipping lint"
  echo "  macOS: brew install shellcheck | Linux: apt install shellcheck"
  exit 0
fi

# Find staged .sh files
STAGED_SH=$(git diff --cached --name-only --diff-filter=ACM -- '*.sh' || true)

if [[ -z "$STAGED_SH" ]]; then
  exit 0
fi

echo "Running ShellCheck on staged scripts..."
FAILED=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if ! shellcheck -x "$f"; then
    FAILED=1
  fi
done <<< "$STAGED_SH"

if [[ "$FAILED" -eq 1 ]]; then
  echo ""
  echo "ShellCheck found issues. Fix them before committing."
  echo "To skip this check: git commit --no-verify"
  exit 1
fi

echo "ShellCheck passed."
