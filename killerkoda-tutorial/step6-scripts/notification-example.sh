#!/bin/bash
# Example security notification logic

SCAN_RESULTS="semgrep-results.json"
CRITICAL_COUNT=$(jq '[.results[] | select(.extra.severity=="ERROR")] | length' $SCAN_RESULTS 2>/dev/null || echo "0")

# Also check dependency and container scan results
DEP_HIGH=$(jq '[.dependencies[].vulnerabilities[] | select(.severity=="HIGH" or .severity=="CRITICAL")] | length' dep-check-reports/dependency-check-report.json 2>/dev/null || echo "0")
CONTAINER_HIGH=$(jq '[.matches[] | select(.vulnerability.severity=="High" or .vulnerability.severity=="Critical")] | length' grype-results.json 2>/dev/null || echo "0")

TOTAL_CRITICAL=$((CRITICAL_COUNT + DEP_HIGH + CONTAINER_HIGH))

if [ "$TOTAL_CRITICAL" -gt 0 ]; then
    # In a real pipeline, send to Slack, email, or ticketing system
    echo "🚨 SECURITY ALERT 🚨"
    echo "Pipeline: DevSecOps Tutorial"
    echo "Repository: devsecops-pipeline-tutorial"
    echo "Critical Vulnerabilities: $TOTAL_CRITICAL"
    echo "├── SAST Critical: $CRITICAL_COUNT"
    echo "├── Dependency High/Critical: $DEP_HIGH"
    echo "└── Container High/Critical: $CONTAINER_HIGH"
    echo ""
    echo "Top SAST Issues:"
    jq -r '.results[] | select(.extra.severity=="ERROR") | "- \(.check_id): \(.path):\(.start.line)"' $SCAN_RESULTS 2>/dev/null | head -5
    echo ""
    echo "Action Required: Fix vulnerabilities before deployment"
    echo "Dashboard: View detailed reports in security artifacts"
    echo ""
    echo "Notification would be sent to:"
    echo "📧 Email: security-team@company.com"
    echo "💬 Slack: #security-alerts"
    echo "🎫 Jira: AUTO-CREATE-TICKET"
else
    echo "✅ No critical security issues detected"
    echo "Deployment approved from security perspective"
fi
