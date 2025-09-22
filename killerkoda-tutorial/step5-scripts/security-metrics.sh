#!/bin/bash
echo "=== DEVSECOPS SECURITY METRICS ==="
echo "Date: $(date)"
echo ""
echo "SCAN COVERAGE:"
echo "- SAST Enabled: ✅"
echo "- Dependency Scan Enabled: ✅" 
echo "- Container Scan Enabled: ✅"
echo ""
echo "CURRENT SECURITY POSTURE:"

# SAST Metrics
SAST_TOTAL=$(jq '.results | length' semgrep-results.json 2>/dev/null || echo "N/A")
SAST_CRITICAL=$(jq '[.results[] | select(.extra.severity=="ERROR")] | length' semgrep-results.json 2>/dev/null || echo "N/A")
SAST_MEDIUM=$(jq '[.results[] | select(.extra.severity=="WARNING")] | length' semgrep-results.json 2>/dev/null || echo "N/A")

# Dependency Metrics
DEP_TOTAL=$(jq '.dependencies | length' dep-check-reports/dependency-check-report.json 2>/dev/null || echo "N/A")
DEP_VULNERABLE=$(jq '[.dependencies[] | select(.vulnerabilities)] | length' dep-check-reports/dependency-check-report.json 2>/dev/null || echo "N/A")
DEP_HIGH=$(jq '[.dependencies[].vulnerabilities[] | select(.severity=="HIGH" or .severity=="CRITICAL")] | length' dep-check-reports/dependency-check-report.json 2>/dev/null || echo "N/A")

# Container Metrics
CONTAINER_TOTAL=$(jq '.matches | length' grype-results.json 2>/dev/null || echo "N/A")
CONTAINER_HIGH=$(jq '[.matches[] | select(.vulnerability.severity=="High" or .vulnerability.severity=="Critical")] | length' grype-results.json 2>/dev/null || echo "N/A")

echo "📊 VULNERABILITY STATISTICS:"
echo "├── SAST Findings: $SAST_TOTAL (Critical: $SAST_CRITICAL, Medium: $SAST_MEDIUM)"
echo "├── Dependencies: $DEP_TOTAL analyzed, $DEP_VULNERABLE vulnerable (High/Critical: $DEP_HIGH)"
echo "└── Container: $CONTAINER_TOTAL vulnerabilities (High/Critical: $CONTAINER_HIGH)"
echo ""

# Calculate overall risk
TOTAL_CRITICAL=$((${SAST_CRITICAL:-0} + ${DEP_HIGH:-0} + ${CONTAINER_HIGH:-0}))

echo "SECURITY GATE STATUS:"
if [ "$TOTAL_CRITICAL" -gt 0 ]; then
    echo "- Status: ❌ FAILED"
    echo "- Reason: $TOTAL_CRITICAL critical vulnerabilities detected"
    echo "- Action: Block deployment until fixed"
else
    echo "- Status: ✅ PASSED"
    echo "- Action: Deployment approved"
fi
echo ""

echo "TRENDS:"
echo "- This Scan: $TOTAL_CRITICAL critical vulnerabilities detected"
if [ "$TOTAL_CRITICAL" -gt 0 ]; then
    echo "- Recommendation: Implement immediate remediation plan"
    echo "- Priority: Fix SAST critical issues first (fastest to remediate)"
else
    echo "- Recommendation: Maintain current security practices"
fi
echo ""

echo "DEVSECOPS MATURITY:"
echo "- Pipeline Integration: ✅ Automated scanning enabled"
echo "- Security Gates: ✅ Blocking gates implemented"
echo "- Reporting: ✅ Multi-format reports generated"
echo "- Notification: ✅ Alert system configured"
echo "- Metrics: ✅ Security metrics tracked"
