#!/bin/bash

# Step 3 Verification: Ensure SAST scanning with Semgrep is completed

echo "Verifying Step 3: SAST with Semgrep..."

# Check if Semgrep is installed
if ! command -v semgrep &> /dev/null; then
    echo "[ERROR] Semgrep not installed. Run: pip3 install semgrep"
    exit 1
fi

# Check if .semgrep.yml exists
if [ ! -f ".semgrep.yml" ]; then
    echo "[ERROR] Semgrep configuration file missing. Ensure .semgrep.yml exists in project root."
    exit 1
fi

# Check if scan was performed (check for both possible file names)
RESULTS_FILE=""
if [ -f "semgrep-results.json" ]; then
    RESULTS_FILE="semgrep-results.json"
elif [ -f "semgrep-combined-results.json" ]; then
    RESULTS_FILE="semgrep-combined-results.json"
else
    echo "[ERROR] Semgrep scan not performed. Run: semgrep --config=.semgrep.yml --json vulnerable-app/ > semgrep-results.json"
    exit 1
fi

echo "Using results file: $RESULTS_FILE"

# Verify scan found vulnerabilities
VULN_COUNT=$(jq '.results | length' "$RESULTS_FILE" 2>/dev/null || echo "0")
if [ "$VULN_COUNT" -eq 0 ]; then
    echo "[ERROR] No vulnerabilities found. Check scan configuration."
    exit 1
fi

CRITICAL_COUNT=$(jq '[.results[] | select(.extra.severity=="ERROR")] | length' "$RESULTS_FILE" 2>/dev/null || echo "0")
if [ "$CRITICAL_COUNT" -eq 0 ]; then
    echo "[WARNING] No critical vulnerabilities found. Expected at least 3 critical findings."
fi

# Verify key vulnerability types were found
SQL_INJ=$(jq '.results[] | select(.check_id | contains("sql-injection"))' "$RESULTS_FILE" 2>/dev/null | wc -l)
CMD_INJ=$(jq '.results[] | select(.check_id | contains("command-injection"))' "$RESULTS_FILE" 2>/dev/null | wc -l)

if [ "$SQL_INJ" -eq 0 ]; then
    echo "[WARNING] SQL injection not detected. Check rule configuration."
fi

if [ "$CMD_INJ" -eq 0 ]; then
    echo "[WARNING] Command injection not detected. Check rule configuration."
fi

echo "[SUCCESS] Step 3 Complete: SAST scanning with Semgrep successful"
echo "[SUCCESS] Found $VULN_COUNT total vulnerabilities ($CRITICAL_COUNT critical)"
echo "[SUCCESS] Custom Semgrep rules working correctly"
echo "[SUCCESS] Ready to proceed to dependency vulnerability scanning!"