#!/usr/bin/env bash
# ============================================================
# deploy-retail-metadata.sh — Deploy retail demo metadata to a scratch org.
#
#   1. Look up the scratch org's admin username.
#   2. Substitute the dashboard's __SCRATCH_ADMIN_USERNAME__ placeholder
#      with that username (in-place; restored on exit so the source stays portable).
#   3. Deploy reports → dashboard → flow in dependency order.
#
# Only deploys *retail* metadata. Other industries' assets in force-app are
# left untouched so this script is safe to run in a mixed repo.
#
# Usage:
#   ./scripts/deploy-retail-metadata.sh [alias]    # default alias: demo-retail
# ============================================================
set -uo pipefail
# Note: -e (exit-on-error) intentionally NOT set — `sf` CLI exits non-zero on
# benign deprecation warnings, which would otherwise abort multi-step deploys
# even when each step succeeded. Each step prints its own Status: Succeeded/Failed.

ALIAS="${1:-demo-retail}"
PLACEHOLDER="__SCRATCH_ADMIN_USERNAME__"
DASHBOARD_REL="force-app/main/default/dashboards/SF_Demo_Hub/Retail_Quarterly_Pipeline_Dashboard.dashboard-meta.xml"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DASHBOARD="$REPO_ROOT/$DASHBOARD_REL"

[[ -f "$DASHBOARD" ]] || { echo "ERROR: dashboard XML not found at $DASHBOARD"; exit 1; }

# --- Verify the alias resolves AND resolve admin username (single sf call).
# Note: sf CLI may exit non-zero on deprecation warnings even when the org is fine,
# so we don't trust the exit code — we look for the Username row in the output. ---
ORG_INFO="$(sf org display --target-org "$ALIAS" 2>&1 || true)"
USERNAME="$(echo "$ORG_INFO" | awk '/^[[:space:]]*│[[:space:]]*Username[[:space:]]/{print $4}' | head -n 1)"
if [[ -z "$USERNAME" ]]; then
  # fallback for older sf versions that print plain key-value rows without box-drawing chars
  USERNAME="$(echo "$ORG_INFO" | awk '/^[[:space:]]*Username[[:space:]]/{print $NF}' | head -n 1)"
fi
if [[ -z "$USERNAME" ]]; then
  echo "ERROR: could not resolve admin username for '$ALIAS'."
  echo "       Verify the alias exists:  sf org display --target-org $ALIAS"
  exit 1
fi
echo "==> Resolved admin username: $USERNAME"

# --- Substitute placeholder; restore on exit so the file in source stays portable.
# Backup goes to /tmp so the .bak file doesn't sit inside force-app and get picked
# up by `sf project deploy start` as an extra dashboard. ---
ORIGINAL_BACKUP="$(mktemp)"
cp "$DASHBOARD" "$ORIGINAL_BACKUP"
echo "==> Substituting dashboard runningUser placeholder ..."
sed -i.tmp "s|$PLACEHOLDER|$USERNAME|g" "$DASHBOARD"
rm -f "$DASHBOARD.tmp"

restore_placeholder() {
  if [[ -f "$ORIGINAL_BACKUP" ]]; then
    cp "$ORIGINAL_BACKUP" "$DASHBOARD"
    rm -f "$ORIGINAL_BACKUP"
    echo "==> Placeholder restored in dashboard XML."
  fi
}
trap restore_placeholder EXIT

# --- Deploy in dependency order: folders → reports → dashboard → flow ---
echo "==> [1/4] Deploying report / dashboard folders ..."
sf project deploy start --target-org "$ALIAS" \
  --metadata "ReportFolder:SF_Demo_Hub" \
  --metadata "DashboardFolder:SF_Demo_Hub"

echo "==> [2/4] Deploying retail reports ..."
sf project deploy start --target-org "$ALIAS" \
  --metadata "Report:SF_Demo_Hub/Retail_Quarterly_Pipeline_Count" \
  --metadata "Report:SF_Demo_Hub/Retail_Quarterly_Pipeline_Amount"

echo "==> [3/4] Deploying retail dashboard ..."
sf project deploy start --target-org "$ALIAS" \
  --metadata "Dashboard:SF_Demo_Hub/Retail_Quarterly_Pipeline_Dashboard"

echo "==> [4/4] Deploying retail flow ..."
sf project deploy start --target-org "$ALIAS" \
  --metadata "Flow:Retail_High_Value_Opportunity_Alert"

echo "============================================================"
echo "  零售 demo metadata deployed to '$ALIAS'."
echo "  Dashboard:  Setup → Dashboards → SF Demo Hub → 零售销售季度漏斗"
echo "  Flow:       Setup → Flows → 零售-高价值商机销售总监提醒"
echo "  Reminder:   Setup → Email → Deliverability → 'All email'"
echo "              (否则 Flow 发的邮件会被静默丢弃)"
echo "============================================================"
