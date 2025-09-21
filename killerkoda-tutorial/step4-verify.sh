#!/bin/bash

# Step 4 Verification: OWASP Dependency-Check run and findings present

echo "Verifying Step 4: Dependency Scanning with OWASP Dependency-Check..."

# Check if dependency-check is installed
if ! command -v dependency-check &> /dev/null; then
    echo "[ERROR] Dependency-Check not installed. Run setup or install it."
    exit 1
fi

# Check if reports exist
if [ ! -d "dep-check-reports" ] && [ ! -d "reports/dependency-check" ]; then
    echo "[ERROR] No Dependency-Check reports found. Run the scan as instructed."
    exit 1
fi

REPORT_JSON=""
if [ -f "dep-check-reports/dependency-check-report.json" ]; then
  REPORT_JSON="dep-check-reports/dependency-check-report.json"
elif [ -f "reports/dependency-check/dependency-check-report.json" ]; then
  REPORT_JSON="reports/dependency-check/dependency-check-report.json"
fi

if [ -z "$REPORT_JSON" ]; then
    echo "[ERROR] JSON report not found. Ensure --format JSON was used."
    exit 1
fi

TOTAL=$(jq '.dependencies | length' "$REPORT_JSON" 2>/dev/null || echo "0")
if [ "$TOTAL" -eq 0 ]; then
    echo "[ERROR] Report seems empty. Re-run the scan."
    exit 1
fi

HIGH_OR_CRIT=$(jq '[.. | objects | select(has("severity")) | .severity | select(.=="HIGH" or .=="CRITICAL")] | length' "$REPORT_JSON" 2>/dev/null || echo "0")

echo "[SUCCESS] Dependency-Check reports found; dependencies analyzed: $TOTAL"
echo "[INFO] High/Critical findings (approx): $HIGH_OR_CRIT"
echo "[SUCCESS] Step 4 Complete: Dependency scanning performed"
echo "Ready to proceed to container image scanning with Grype!"


