#!/bin/bash

# Step 3 Verification: Ultra-simple SAST check

echo "Verifying Step 3: SAST with Semgrep..."

# Only check if semgrep is installed
if ! command -v semgrep &> /dev/null; then
    echo "[ERROR] Semgrep not installed."
    exit 1
fi

# Check if any semgrep file exists
if [ -f "semgrep-results.json" ] || [ -f "semgrep-combined-results.json" ] || [ -f "semgrep-custom-results.json" ] || [ -f "semgrep-community-results.json" ]; then
    echo "[SUCCESS] Step 3 Complete: Semgrep installed and scan files found"
    echo "[SUCCESS] Ready to proceed to dependency vulnerability scanning!"
    exit 0
else
    echo "[ERROR] No semgrep results files found. Run a semgrep scan first."
    exit 1
fi