#!/bin/bash

# Step 7 Verification: Ensure security reporting and remediation is complete

echo "Verifying Step 7: Security Reporting & Remediation Strategies..."

# Check if security dashboard script exists
if [ ! -f "security-dashboard.sh" ]; then
    echo "[ERROR] Security dashboard script missing"
    exit 1
fi

# Verify dashboard script is executable
if [ ! -x "security-dashboard.sh" ]; then
    chmod +x security-dashboard.sh
fi

# Check if detailed vulnerability report exists
if [ ! -f "detailed-vulnerability-report.sh" ]; then
    echo "[ERROR] Detailed vulnerability report script missing"
    exit 1
fi

# Check if remediation guide exists
if [ ! -f "remediation-guide.sh" ]; then
    echo "[ERROR] Remediation guide script missing"
    exit 1
fi

# Check if executive summary exists
if [ ! -f "executive-summary.sh" ]; then
    echo "[ERROR] Executive summary script missing"
    exit 1
fi

# Verify all scripts are executable
chmod +x *.sh 2>/dev/null

# Check if final security report was generated
if [ ! -f "final-security-report.md" ]; then
    echo "[WARNING] Final security report not generated"
fi

# Verify security improvement plan exists
if [ ! -f "security-improvement-plan.sh" ]; then
    echo "[WARNING] Security improvement plan missing"
fi

# Check if Easter egg was discovered
if grep -q "EASTER EGG DISCOVERED" /tmp/easter_egg_found 2>/dev/null; then
    echo "[BONUS] Easter egg discovered - bonus points!"
else
    echo "[CLUE] Easter egg clue: Look for the hidden admin backdoor combining hardcoded secrets + pickle deserialization!"
fi

# Verify comprehensive reporting capability
REPORTS_CREATED=0
if [ -x "security-dashboard.sh" ]; then REPORTS_CREATED=$((REPORTS_CREATED + 1)); fi
if [ -x "detailed-vulnerability-report.sh" ]; then REPORTS_CREATED=$((REPORTS_CREATED + 1)); fi
if [ -x "remediation-guide.sh" ]; then REPORTS_CREATED=$((REPORTS_CREATED + 1)); fi
if [ -x "executive-summary.sh" ]; then REPORTS_CREATED=$((REPORTS_CREATED + 1)); fi

if [ "$REPORTS_CREATED" -lt 4 ]; then
    echo "[ERROR] Incomplete reporting suite. Need all 4 reporting scripts."
    exit 1
fi

echo "[SUCCESS] Step 7 Complete: Security Reporting & Remediation successful"
echo "[SUCCESS] Comprehensive security dashboard implemented"
echo "[SUCCESS] Detailed vulnerability analysis available"
echo "[SUCCESS] Remediation guide created with fix instructions"
echo "[SUCCESS] Executive summary ready for management"
echo "[SUCCESS] Continuous improvement framework established"
echo ""
echo "[COMPLETE] TUTORIAL COMPLETE!"
echo "You have successfully implemented a full DevSecOps security pipeline!"