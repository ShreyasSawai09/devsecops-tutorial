#!/bin/bash
echo "=== THRESHOLD-BASED SECURITY GATE ==="

# Allow up to 2 medium-risk findings, but no critical
CRITICAL_THRESHOLD=0
MEDIUM_THRESHOLD=2

SEMGREP_CRITICAL=$(jq '[.results[] | select(.extra.severity=="ERROR")] | length' semgrep-results.json 2>/dev/null || echo "0")
SEMGREP_MEDIUM=$(jq '[.results[] | select(.extra.severity=="WARNING")] | length' semgrep-results.json 2>/dev/null || echo "0")

# Add dependency and container findings
DEP_HIGH=$(jq '[.dependencies[].vulnerabilities[] | select(.severity=="HIGH" or .severity=="CRITICAL")] | length' dep-check-reports/dependency-check-report.json 2>/dev/null || echo "0")
DEP_MEDIUM=$(jq '[.dependencies[].vulnerabilities[] | select(.severity=="MEDIUM")] | length' dep-check-reports/dependency-check-report.json 2>/dev/null || echo "0")

CONTAINER_HIGH=$(jq '[.matches[] | select(.vulnerability.severity=="High" or .vulnerability.severity=="Critical")] | length' grype-results.json 2>/dev/null || echo "0")
CONTAINER_MEDIUM=$(jq '[.matches[] | select(.vulnerability.severity=="Medium")] | length' grype-results.json 2>/dev/null || echo "0")

TOTAL_CRITICAL=$((SEMGREP_CRITICAL + DEP_HIGH + CONTAINER_HIGH))
TOTAL_MEDIUM=$((SEMGREP_MEDIUM + DEP_MEDIUM + CONTAINER_MEDIUM))

echo "Critical findings: $TOTAL_CRITICAL (threshold: $CRITICAL_THRESHOLD)"
echo "Medium findings: $TOTAL_MEDIUM (threshold: $MEDIUM_THRESHOLD)"

if [ "$TOTAL_CRITICAL" -gt "$CRITICAL_THRESHOLD" ]; then
    echo "BUILD FAILED: Critical vulnerabilities exceed threshold"
    echo "🚨 SECURITY GATE FAILED - CRITICAL THRESHOLD EXCEEDED"
    exit 1
elif [ "$TOTAL_MEDIUM" -gt "$MEDIUM_THRESHOLD" ]; then
    echo "BUILD FAILED: Medium vulnerabilities exceed threshold"  
    echo "⚠️ SECURITY GATE FAILED - MEDIUM THRESHOLD EXCEEDED"
    exit 1
else
    echo "BUILD PASSED: All findings within acceptable thresholds"
    echo "✅ SECURITY GATE PASSED - THRESHOLD POLICY"
fi
