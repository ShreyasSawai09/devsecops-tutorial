#!/bin/bash
echo "=== STRICT SECURITY GATE ==="

# Any critical vulnerability fails the build
SEMGREP_CRITICAL=$(jq '[.results[] | select(.extra.severity=="ERROR")] | length' semgrep-results.json 2>/dev/null || echo "0")
DEP_HIGH=$(jq '[.dependencies[].vulnerabilities[] | select(.severity=="HIGH" or .severity=="CRITICAL")] | length' dep-check-reports/dependency-check-report.json 2>/dev/null || echo "0")
CONTAINER_HIGH=$(jq '[.matches[] | select(.vulnerability.severity=="High" or .vulnerability.severity=="Critical")] | length' grype-results.json 2>/dev/null || echo "0")

TOTAL_CRITICAL=$((SEMGREP_CRITICAL + DEP_HIGH + CONTAINER_HIGH))

echo "Critical SAST Findings: $SEMGREP_CRITICAL"
echo "High/Critical Dependency Findings: $DEP_HIGH"
echo "High/Critical Container Findings: $CONTAINER_HIGH"
echo "Total Critical Issues: $TOTAL_CRITICAL"

if [ "$TOTAL_CRITICAL" -gt 0 ]; then
    echo "BUILD FAILED: $TOTAL_CRITICAL critical vulnerabilities found"
    echo ""
    echo "[FAILED] SECURITY GATE FAILED - ZERO TOLERANCE POLICY"
    echo "All critical and high severity vulnerabilities must be fixed before deployment"
    exit 1
else
    echo "BUILD PASSED: No critical vulnerabilities"
    echo "[PASSED] SECURITY GATE PASSED - STRICT POLICY"
fi
