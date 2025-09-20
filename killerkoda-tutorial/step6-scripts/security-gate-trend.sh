#!/bin/bash
echo "=== TREND-BASED SECURITY GATE ==="

# Fail if security posture is getting worse
# (In practice, you'd compare against previous scan results)

CURRENT_ISSUES=$(jq '.results | length' semgrep-results.json 2>/dev/null || echo "0")
echo "Current scan: $CURRENT_ISSUES total issues"

# Simulate previous scan results for demo
PREVIOUS_ISSUES=3
echo "Previous scan: $PREVIOUS_ISSUES total issues"

# Add dependency and container trend analysis
CURRENT_DEP=$(jq '.dependencies | length' dep-check-reports/dependency-check-report.json 2>/dev/null || echo "0")
CURRENT_CONTAINER=$(jq '.matches | length' grype-results.json 2>/dev/null || echo "0")

TOTAL_CURRENT=$((CURRENT_ISSUES + CURRENT_DEP + CURRENT_CONTAINER))
TOTAL_PREVIOUS=15  # Simulated baseline

echo "Total current vulnerabilities: $TOTAL_CURRENT"
echo "Total previous vulnerabilities: $TOTAL_PREVIOUS"

if [ "$TOTAL_CURRENT" -gt "$TOTAL_PREVIOUS" ]; then
    echo "BUILD FAILED: Security posture degraded ($TOTAL_CURRENT vs $TOTAL_PREVIOUS)"
    echo "🚨 SECURITY GATE FAILED - SECURITY REGRESSION DETECTED"
    echo "New vulnerabilities introduced - please review"
    exit 1
else
    IMPROVEMENT=$((TOTAL_PREVIOUS - TOTAL_CURRENT))
    echo "BUILD PASSED: Security posture maintained or improved"
    echo "✅ SECURITY GATE PASSED - TREND ANALYSIS"
    if [ "$IMPROVEMENT" -gt 0 ]; then
        echo "🎉 Security improvement: $IMPROVEMENT fewer vulnerabilities than previous scan"
    fi
fi
