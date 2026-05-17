#!/usr/bin/env bash
# ============================================================
# deploy-list-views.sh — Deploy "All Records" list views to a scratch org.
#
# Industry-agnostic. Creates a public list view with filterScope=Everything
# on each of the 5 core CRM standard objects so the demo presenter can
# instantly see all seeded data without configuring views in the UI.
#
# Usage:
#   ./scripts/deploy-list-views.sh [alias]    # default alias: 'default org'
# ============================================================
set -uo pipefail
# Note: -e NOT set because `sf` exits non-zero on benign deprecation warnings.

ALIAS="${1:-}"
if [[ -z "$ALIAS" ]]; then
  TARGET_FLAG=""
  echo "==> No alias provided; deploying to current default org."
else
  TARGET_FLAG="--target-org $ALIAS"
fi

OBJECTS=(Account Contact Opportunity Lead Case)
META_FLAGS=""
for obj in "${OBJECTS[@]}"; do
  META_FLAGS="$META_FLAGS --metadata ListView:${obj}.All_Records"
done

echo "==> Deploying All_Records list views for: ${OBJECTS[*]}"
# shellcheck disable=SC2086
sf project deploy start $TARGET_FLAG $META_FLAGS

echo "============================================================"
echo "  Done. Each object now has an 'All Records' list view."
echo "  Open any object's tab in the org to switch to it."
echo "============================================================"
