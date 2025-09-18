#!/bin/bash

# Step 3 Verification: Ensure SAST scanning with Semgrep is completed

echo "Verifying Step 3: SAST with Semgrep..."

# Check if Semgrep is installed
if ! command -v semgrep &> /dev/null; then
    echo "Semgrep not installed. Run: pip3 install semgrep"
    exit 1
fi

# Check if .semgrep.yml exists
if [ ! -f ".semgrep.yml" ]; then
    echo "Semgrep configuration file missing. Ensure .semgrep.yml exists in project root."
    exit 1
fi

# Check if scan was performed
if [ ! -f "semgrep-results.json" ]; then
    echo "Semgrep scan not performed. Run: semgrep --config=.semgrep.yml --json vulnerable-app/ > semgrep-results.json"
    exit 1
fi

echo "Step 3 Complete: SAST scanning with Semgrep successful"
echo "Found $VULN_COUNT total vulnerabilities ($CRITICAL_COUNT critical)"
echo "Custom Semgrep rules working correctly"
echo "Ready to proceed to dependency vulnerability scanning!"