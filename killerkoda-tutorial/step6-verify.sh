#!/bin/bash

# Step 6 Verification: Ensure CI/CD pipeline and security gates are implemented

echo "Verifying Step 6: CI/CD Pipeline Integration & Security Gates..."

# Check if GitHub Actions workflow exists
if [ ! -f ".github/workflows/security-scan.yml" ]; then
    echo "❌ GitHub Actions workflow missing. Create .github/workflows/security-scan.yml"
    exit 1
fi

# Verify workflow contains all three security tools
if ! grep -q "semgrep" .github/workflows/security-scan.yml; then
    echo "❌ Semgrep not configured in CI/CD pipeline"
    exit 1
fi

if ! grep -q "dependency-check" .github/workflows/security-scan.yml; then
    echo "❌ OWASP Dependency Check not configured in CI/CD pipeline"
    exit 1
fi

if ! grep -q "grype" .github/workflows/security-scan.yml; then
    echo "❌ Grype not configured in CI/CD pipeline"
    exit 1
fi

# Check if security gate scripts exist
GATE_SCRIPTS=0
if [ -f "security-gate-strict.sh" ]; then
    GATE_SCRIPTS=$((GATE_SCRIPTS + 1))
fi
if [ -f "security-gate-threshold.sh" ]; then
    GATE_SCRIPTS=$((GATE_SCRIPTS + 1))
fi
if [ -f "security-gate-trend.sh" ]; then
    GATE_SCRIPTS=$((GATE_SCRIPTS + 1))
fi

if [ "$GATE_SCRIPTS" -lt 2 ]; then
    echo "❌ Security gate scripts missing. Create at least 2 gate strategy scripts."
    exit 1
fi

# Verify security gates can execute
chmod +x security-gate-*.sh 2>/dev/null

# Check if notification system is configured
if [ ! -f "notification-example.sh" ]; then
    echo "⚠️  Notification system not configured (optional)"
fi

# Verify security metrics script exists
if [ ! -f "security-metrics.sh" ]; then
    echo "⚠️  Security metrics script missing (optional)"
fi

echo "✅ Step 6 Complete: CI/CD Pipeline Integration successful"
echo "✅ GitHub Actions workflow configured with all security tools"
echo "✅ Security gates implemented with multiple strategies"
echo "✅ Pipeline ready for automated security testing"
echo "Ready to proceed to security reporting and remediation!"