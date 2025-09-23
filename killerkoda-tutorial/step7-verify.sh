#!/bin/bash

# Consolidated Final Verification (Step 7): Run all checks at the end
set -e

echo "Running consolidated final verification for all steps..."

PASS=true

# ---- Step 1 checks ----
echo "[Step 1] Checking environment (python3, git, docker)"
if ! command -v python3 &> /dev/null; then echo "[Step 1] Python 3 not found"; PASS=false; fi
if ! command -v git &> /dev/null; then echo "[Step 1] Git not found"; PASS=false; fi
if ! command -v docker &> /dev/null; then echo "[Step 1] Docker not found"; PASS=false; fi

# ---- Step 2 checks ----
echo "[Step 2] Checking vulnerable app setup"
if [ ! -f "vulnerable-app/app.py" ] && [ ! -f "devsecops-pipeline-tutorial/vulnerable-app/app.py" ]; then
  echo "[Step 2] Vulnerable app not found at expected path"; PASS=false
fi
if python3 -c "import flask" 2>/dev/null; then echo "[Step 2] Flask available"; else echo "[Step 2] Flask not installed"; PASS=false; fi

# ---- Step 3 checks ----
echo "[Step 3] Checking Semgrep results"
RESULTS_FILE=""
if [ -f "semgrep-results.json" ]; then RESULTS_FILE="semgrep-results.json"; fi
if [ -z "$RESULTS_FILE" ] && [ -f "semgrep-combined-results.json" ]; then RESULTS_FILE="semgrep-combined-results.json"; fi
if [ -z "$RESULTS_FILE" ]; then echo "[Step 3] Semgrep results not found"; PASS=false; else
  VULN_COUNT=$(jq '.results | length' "$RESULTS_FILE" 2>/dev/null || echo "0")
  if [ "$VULN_COUNT" -eq 0 ]; then echo "[Step 3] No Semgrep findings"; PASS=false; fi
fi

# ---- Step 4 checks ----
echo "[Step 4] Checking Dependency-Check report"
REPORT_JSON=""
if [ -f "dep-check-reports/dependency-check-report.json" ]; then REPORT_JSON="dep-check-reports/dependency-check-report.json"; fi
if [ -z "$REPORT_JSON" ] && [ -f "reports/dependency-check/dependency-check-report.json" ]; then REPORT_JSON="reports/dependency-check/dependency-check-report.json"; fi
if [ -z "$REPORT_JSON" ]; then echo "[Step 4] Dependency-Check JSON report not found"; PASS=false; else
  TOTAL=$(jq '.dependencies | length' "$REPORT_JSON" 2>/dev/null || echo "0")
  if [ "$TOTAL" -eq 0 ]; then echo "[Step 4] Empty dependency report"; PASS=false; fi
fi

# ---- Step 5 checks (Grype) ----
echo "[Step 5] Checking Grype image scan results"
if ! command -v grype &> /dev/null; then
  echo "[Step 5] Grype not installed"; PASS=false
else
  if [ -f "grype-results.json" ]; then
    GCOUNT=$(jq '.matches | length' grype-results.json 2>/dev/null || echo "0")
    if [ "$GCOUNT" -eq 0 ]; then echo "[Step 5] Grype results contain no matches"; PASS=false; fi
  else
    echo "[Step 5] grype-results.json not found"; PASS=false
  fi
fi

# ---- Step 6 checks ----
echo "[Step 6] Checking CI/CD pipeline config"
if [ -f ".github/workflows/security-scan.yml" ]; then
  if ! grep -q "semgrep" .github/workflows/security-scan.yml; then echo "[Step 6] Semgrep not in workflow"; PASS=false; fi
  if ! grep -q "dependency-check" .github/workflows/security-scan.yml; then echo "[Step 6] dependency-check not in workflow"; PASS=false; fi
  if ! grep -q "grype" .github/workflows/security-scan.yml; then echo "[Step 6] grype not in workflow"; PASS=false; fi
else
  echo "[Step 6] Workflow file missing"; PASS=false
fi

# ---- Step 7 checks (Reporting) ----
echo "[Step 7] Checking reporting scripts"
missing7=0
for f in security-dashboard.sh detailed-vulnerability-report.sh remediation-guide.sh executive-summary.sh; do
  if [ ! -f "$f" ]; then echo "[Step 7] Missing $f"; missing7=$((missing7+1)); fi
done
if [ $missing7 -gt 0 ]; then PASS=false; fi

if [ "$PASS" = true ]; then
  echo "\n✅ All steps verified successfully."
  echo "🎉 TUTORIAL COMPLETE! 🎉"
  exit 0
else
  echo "\n❌ Final verification found issues. Review the messages above and re-run."
  exit 1
fi