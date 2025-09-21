#!/bin/bash

echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
echo "║                          DEVSECOPS SECURITY DASHBOARD                        ║"
echo "╠═══════════════════════════════════════════════════════════════════════════════╣"
echo "║  Application: VulnShop                                                        ║"
echo "║  Scan Date: $(date)                                ║"
echo "║  Pipeline: Automated DevSecOps Security Scanning                             ║"
echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
echo ""

# SAST Results
echo "[SAST] STATIC APPLICATION SECURITY TESTING (SAST) - Semgrep"
echo "════════════════════════════════════════════════════════════════"
if [ -f semgrep-results.json ]; then
    TOTAL_SAST=$(jq '.results | length' semgrep-results.json)
    CRITICAL_SAST=$(jq '[.results[] | select(.extra.severity=="ERROR")] | length' semgrep-results.json)
    WARNING_SAST=$(jq '[.results[] | select(.extra.severity=="WARNING")] | length' semgrep-results.json)
    
    echo "Status: [ISSUES FOUND]"
    echo "Total Findings: $TOTAL_SAST"
    echo "├── Critical (ERROR): $CRITICAL_SAST"
    echo "└── Warning: $WARNING_SAST"
    echo ""
    echo "Top Critical Issues:"
    jq -r '.results[] | select(.extra.severity=="ERROR") | "  • \(.check_id) (\(.path):\(.start.line))"' semgrep-results.json | head -5
else
    echo "Status: [NOT SCANNED]"
fi
echo ""

# Dependency Scan Results  
echo "[DEPENDENCY] DEPENDENCY VULNERABILITY SCANNING - OWASP Dependency Check"
echo "════════════════════════════════════════════════════════════════"
if [ -f dep-check-reports/dependency-check-report.json ]; then
    TOTAL_DEPS=$(jq '.dependencies | length' dep-check-reports/dependency-check-report.json)
    VULNERABLE_DEPS=$(jq '[.dependencies[] | select(.vulnerabilities)] | length' dep-check-reports/dependency-check-report.json)
    HIGH_DEPS=$(jq '[.dependencies[].vulnerabilities[] | select(.severity=="HIGH" or .severity=="CRITICAL")] | length' dep-check-reports/dependency-check-report.json 2>/dev/null || echo "0")
    MEDIUM_DEPS=$(jq '[.dependencies[].vulnerabilities[] | select(.severity=="MEDIUM")] | length' dep-check-reports/dependency-check-report.json 2>/dev/null || echo "0")
    
    echo "Status: [VULNERABILITIES FOUND]"
    echo "Total Dependencies: $TOTAL_DEPS"
    echo "Vulnerable Dependencies: $VULNERABLE_DEPS"
    echo "├── High/Critical Severity: $HIGH_DEPS"
    echo "└── Medium Severity: $MEDIUM_DEPS"
else
    echo "Status: [NOT SCANNED]"
    echo "Note: Dependency scan results would show vulnerable packages"
    echo "Expected findings: urllib3, setuptools, requests, pyyaml, pillow, cryptography"
fi
echo ""

# Container Scan Results
echo "[CONTAINER] CONTAINER IMAGE SCANNING - Grype"  
echo "════════════════════════════════════════════════════════════════"
if [ -f grype-results.json ]; then
    CONTAINER_VULNS=$(jq '.matches | length' grype-results.json 2>/dev/null || echo "0")
    CONTAINER_HIGH=$(jq '[.matches[] | select(.vulnerability.severity=="High" or .vulnerability.severity=="Critical")] | length' grype-results.json 2>/dev/null || echo "0")
    CONTAINER_MEDIUM=$(jq '[.matches[] | select(.vulnerability.severity=="Medium")] | length' grype-results.json 2>/dev/null || echo "0")
    
    echo "Status: [VULNERABILITIES FOUND]"
    echo "Container Vulnerabilities: $CONTAINER_VULNS"
    echo "├── High/Critical: $CONTAINER_HIGH"
    echo "└── Medium: $CONTAINER_MEDIUM"
else
    echo "Status: [NOT SCANNED]"
    echo "Note: Container scan would show base image and package vulnerabilities"
fi
echo ""

# Security Gate Status
echo "[SECURITY GATE] SECURITY GATE EVALUATION"
echo "════════════════════════════════════════════════════════════════"

# Calculate total critical issues
TOTAL_CRITICAL=0
if [ -f semgrep-results.json ]; then
    TOTAL_CRITICAL=$((TOTAL_CRITICAL + $(jq '[.results[] | select(.extra.severity=="ERROR")] | length' semgrep-results.json)))
fi
if [ -f dep-check-reports/dependency-check-report.json ]; then
    TOTAL_CRITICAL=$((TOTAL_CRITICAL + $(jq '[.dependencies[].vulnerabilities[] | select(.severity=="HIGH" or .severity=="CRITICAL")] | length' dep-check-reports/dependency-check-report.json 2>/dev/null || echo "0")))
fi
if [ -f grype-results.json ]; then
    TOTAL_CRITICAL=$((TOTAL_CRITICAL + $(jq '[.matches[] | select(.vulnerability.severity=="High" or .vulnerability.severity=="Critical")] | length' grype-results.json 2>/dev/null || echo "0")))
fi

if [ "$TOTAL_CRITICAL" -gt 0 ]; then
    echo "Overall Status: [FAILED]"
    echo "Critical Issues Found: $TOTAL_CRITICAL"
    echo "Reason: Critical vulnerabilities detected across security scans"
    echo "Action Required: Fix critical findings before deployment"
    echo "Deployment: [BLOCKED]"
else
    echo "Overall Status: [PASSED]"  
    echo "Deployment: [APPROVED]"
fi
echo ""

# Remediation Priority
echo "[REMEDIATION] REMEDIATION PRIORITY MATRIX"
echo "════════════════════════════════════════════════════════════════"
echo "Priority 1 (Critical): Fix immediately before any deployment"
if [ -f semgrep-results.json ]; then
    jq -r '.results[] | select(.extra.severity=="ERROR") | "  • \(.check_id): \(.extra.message | split(".")[0])"' semgrep-results.json
fi
if [ -f dep-check-reports/dependency-check-report.json ]; then
    jq -r '.dependencies[] | select(.vulnerabilities) | select(.vulnerabilities[] | .severity=="CRITICAL") | "  • Dependency: \(.fileName) - Critical CVEs"' dep-check-reports/dependency-check-report.json 2>/dev/null
fi
echo ""
echo "Priority 2 (High): Fix within 1 week"
if [ -f dep-check-reports/dependency-check-report.json ]; then
    jq -r '.dependencies[] | select(.vulnerabilities) | select(.vulnerabilities[] | .severity=="HIGH") | "  • Dependency: \(.fileName) - High severity CVEs"' dep-check-reports/dependency-check-report.json 2>/dev/null
fi
if [ -f grype-results.json ]; then
    echo "  • Container base image vulnerabilities (High severity)"
fi
echo ""
echo "Priority 3 (Medium): Fix within 1 month"  
if [ -f semgrep-results.json ]; then
    jq -r '.results[] | select(.extra.severity=="WARNING") | "  • \(.check_id): \(.extra.message | split(".")[0])"' semgrep-results.json
fi
