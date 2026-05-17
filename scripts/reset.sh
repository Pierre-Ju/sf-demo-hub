#!/usr/bin/env bash
# ============================================================
# reset.sh — delete a scratch org by alias (idempotent).
# Usage:  ./scripts/reset.sh <alias>
# Example: ./scripts/reset.sh demo-finance
# ============================================================
set -euo pipefail

ALIAS="${1:-}"

if [[ -z "$ALIAS" ]]; then
  echo "Usage: $0 <scratch-org-alias>"
  echo "Example: $0 demo-finance"
  exit 1
fi

# Does the alias resolve to an org?
if ! sf org display --target-org "$ALIAS" > /dev/null 2>&1; then
  echo "==> No org found for alias '$ALIAS' — nothing to delete."
  exit 0
fi

echo "==> Deleting scratch org '$ALIAS'..."
sf org delete scratch --target-org "$ALIAS" --no-prompt

echo "==> Done. Alias '$ALIAS' is free to reuse."
