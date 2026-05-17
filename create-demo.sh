#!/usr/bin/env bash
# ============================================================
# create-demo.sh — one-shot scratch-org demo bootstrap.
#
# Usage:
#   ./create-demo.sh <industry> [duration-days]
#
# <industry>       one of: manufacturing | retail | healthcare | finance
# [duration-days]  scratch org lifetime, defaults to 7 (max 30)
#
# What it does:
#   1. Validates the industry and locates config/seed files
#   2. Creates a scratch org aliased as 'demo-<industry>' and sets it default
#   3. Runs the matching Apex seed script
#   4. Opens the org in your browser
#
# Re-running with the same industry is safe:
#   - if the alias is already in use, it bails (use scripts/reset.sh first)
#   - if seed data is already present, the Apex script skips itself
# ============================================================
set -euo pipefail

INDUSTRY="${1:-}"
DURATION="${2:-7}"

VALID_INDUSTRIES=(manufacturing retail healthcare finance)

usage() {
  echo "Usage: $0 <industry> [duration-days]"
  echo "  industry: one of: ${VALID_INDUSTRIES[*]}"
  echo "  duration-days: 1-30 (default 7)"
}

if [[ -z "$INDUSTRY" ]]; then
  usage; exit 1
fi

# --- Validate industry ---
match=0
for v in "${VALID_INDUSTRIES[@]}"; do
  [[ "$INDUSTRY" == "$v" ]] && match=1 && break
done
if [[ $match -eq 0 ]]; then
  echo "ERROR: unknown industry '$INDUSTRY'"
  usage; exit 1
fi

# --- Resolve paths relative to this script ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config/${INDUSTRY}-scratch-def.json"
SEED_FILE="$SCRIPT_DIR/scripts/apex/seed-${INDUSTRY}.apex"
ALIAS="demo-${INDUSTRY}"

[[ -f "$CONFIG_FILE" ]] || { echo "ERROR: scratch-def not found at $CONFIG_FILE"; exit 1; }
[[ -f "$SEED_FILE"   ]] || { echo "ERROR: seed script not found at $SEED_FILE"; exit 1; }

# --- Refuse to overwrite an existing alias ---
if sf org display --target-org "$ALIAS" > /dev/null 2>&1; then
  echo "ERROR: alias '$ALIAS' is already in use."
  echo "       Delete it first:  ./scripts/reset.sh $ALIAS"
  exit 1
fi

echo "============================================================"
echo "  Industry : $INDUSTRY"
echo "  Alias    : $ALIAS"
echo "  Config   : $CONFIG_FILE"
echo "  Duration : $DURATION day(s)"
echo "============================================================"

echo "==> [1/3] Creating scratch org..."
sf org create scratch \
  --definition-file "$CONFIG_FILE" \
  --alias "$ALIAS" \
  --duration-days "$DURATION" \
  --set-default \
  --wait 15

echo "==> [2/3] Seeding demo data..."
sf apex run --target-org "$ALIAS" --file "$SEED_FILE"

echo "==> [3/3] Opening org in browser..."
sf org open --target-org "$ALIAS"

echo "============================================================"
echo "  Done. To tear it down later:"
echo "    ./scripts/reset.sh $ALIAS"
echo "============================================================"
