# Step 4: Dependency Vulnerability Scanning with OWASP Dependency-Check

In this step, you'll scan third-party dependencies used by the vulnerable Flask app and learn how dependency vulnerabilities block the pipeline.

## Why dependency scanning?

- **Finds known CVEs** in libraries and transitive dependencies
- **Detects vulnerable versions** early to prevent supply-chain risks
- **Identifies license compliance** issues
- **Tracks security debt** in third-party components

## Understanding Dependency Vulnerabilities

Modern applications rely heavily on third-party packages. A typical Python application might have:
- **Direct dependencies**: Packages you explicitly install (Flask, requests)
- **Transitive dependencies**: Packages that your dependencies depend on
- **Security risk**: Any vulnerable package in the dependency tree affects your application

Let's examine our vulnerable application's dependencies:

```bash
cd devsecops-pipeline-tutorial
cat vulnerable-app/requirements.txt
```{{exec}}

Notice the deliberately vulnerable packages:
- `urllib3==1.26.5` - Known security vulnerabilities
- `setuptools==65.5.0` - Older version with potential issues
- `pyyaml==5.4.1` - Has known deserialization vulnerabilities
- `pillow==8.3.2` - Image processing library with security flaws
- `cryptography==3.4.8` - Cryptographic library with known issues

## Installing OWASP Dependency-Check

First, let's install the OWASP Dependency-Check tool:

```bash
# Download and install Dependency-Check
wget https://github.com/jeremylong/DependencyCheck/releases/download/v8.4.0/dependency-check-8.4.0-release.zip
unzip dependency-check-8.4.0-release.zip
chmod +x dependency-check/bin/dependency-check.sh
```{{exec}}

Verify the installation:
```bash
./dependency-check/bin/dependency-check.sh --version
```{{exec}}

## Running Your First Dependency Scan

Let's run a comprehensive dependency scan:

```bash
# Generate HTML and JSON reports
./dependency-check/bin/dependency-check.sh \
  --project VulnShop \
  --scan vulnerable-app/ \
  --format "HTML,JSON,SARIF" \
  --out dep-check-reports \
  --prettyPrint
```{{exec}}

This will take a few minutes as it downloads the CVE database and analyzes dependencies.

## Analyzing Dependency Scan Results

Once the scan completes, let's examine the results:

```bash
echo "=== DEPENDENCY SCAN RESULTS ==="
echo "Report files generated:"
ls -la dep-check-reports/
```{{exec}}

View the JSON results for programmatic analysis:
```bash
if [ -f "dep-check-reports/dependency-check-report.json" ]; then
  echo "Total dependencies analyzed: $(jq '.dependencies | length' dep-check-reports/dependency-check-report.json)"
  echo "Dependencies with vulnerabilities: $(jq '[.dependencies[] | select(.vulnerabilities)] | length' dep-check-reports/dependency-check-report.json)"
  echo ""
  echo "Vulnerability breakdown by severity:"
  jq -r '.dependencies[].vulnerabilities[]?.severity' dep-check-reports/dependency-check-report.json 2>/dev/null | sort | uniq -c || echo "No vulnerabilities found"
fi
```{{exec}}

## Understanding CVE Details

Let's examine specific vulnerabilities found:

```bash
if [ -f "dep-check-reports/dependency-check-report.json" ]; then
  echo "=== HIGH/CRITICAL VULNERABILITIES ==="
  jq -r '.dependencies[] | select(.vulnerabilities) | 
    {
      fileName: .fileName,
      vulnerabilities: [.vulnerabilities[] | select(.severity == "HIGH" or .severity == "CRITICAL")]
    } | 
    select(.vulnerabilities | length > 0) |
    "Package: \(.fileName)\nVulnerabilities: \(.vulnerabilities | length)\n" +
    (.vulnerabilities[] | "- CVE: \(.name)\n  Severity: \(.severity)\n  CVSS: \(.cvssV3.baseScore // .cvssV2.score // "N/A")\n  Description: \(.description[0:200])...\n")' dep-check-reports/dependency-check-report.json
fi
```{{exec}}

## Configure suppression and thresholds

The repository includes `dependency-check.properties` to customize scanning. Let's examine it:

```bash
cat dependency-check.properties
```{{exec}}

Key configuration options:
- **Database settings**: CVE data source configuration
- **Suppression rules**: False positive management
- **Analysis settings**: What types of files to analyze

## Security Gate Implementation

In CI/CD, we typically fail builds on high-severity vulnerabilities:

```bash
cat > dependency-security-gate.sh << 'EOF'
#!/bin/bash
echo "=== DEPENDENCY SECURITY GATE ==="

if [ ! -f "dep-check-reports/dependency-check-report.json" ]; then
  echo "❌ No dependency scan results found"
  exit 1
fi

# Count high and critical vulnerabilities
HIGH_CRITICAL=$(jq '[.dependencies[].vulnerabilities[] | select(.severity == "HIGH" or .severity == "CRITICAL")] | length' dep-check-reports/dependency-check-report.json 2>/dev/null || echo "0")

echo "High/Critical vulnerabilities found: $HIGH_CRITICAL"

if [ "$HIGH_CRITICAL" -gt 0 ]; then
  echo "🚨 SECURITY GATE FAILED: High/Critical dependency vulnerabilities detected"
  echo ""
  echo "Vulnerable packages:"
  jq -r '.dependencies[] | select(.vulnerabilities) | 
    select(.vulnerabilities[] | .severity == "HIGH" or .severity == "CRITICAL") |
    "- \(.fileName): \([.vulnerabilities[] | select(.severity == "HIGH" or .severity == "CRITICAL")] | length) vulnerabilities"' dep-check-reports/dependency-check-report.json
  echo ""
  echo "Action required: Update vulnerable dependencies before deployment"
  exit 1
else
  echo "✅ SECURITY GATE PASSED: No high/critical dependency vulnerabilities"
fi
EOF

chmod +x dependency-security-gate.sh
./dependency-security-gate.sh
```{{exec}}

## Remediation Strategies

When vulnerabilities are found, here are common remediation approaches:

### 1. Direct Dependency Updates
```bash
echo "=== DEPENDENCY REMEDIATION GUIDE ==="
echo ""
echo "For direct dependencies (in requirements.txt):"
echo "1. Update to latest secure version:"
echo "   pip install --upgrade package_name"
echo "2. Pin to specific secure version:"
echo "   package_name==X.Y.Z"
echo ""
echo "For transitive dependencies:"
echo "1. Update parent dependency"
echo "2. Add explicit pin for transitive dependency"
echo "3. Use dependency resolution tools like pip-tools"
```{{exec}}

### 2. Vulnerability Suppression
For false positives or accepted risks, create suppression rules:

```bash
cat > example-suppression.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<suppressions xmlns="https://jeremylong.github.io/DependencyCheck/dependency-suppression.1.3.xsd">
    <!-- Example: Suppress specific CVE for a package -->
    <suppress>
        <notes>False positive - not applicable to our usage</notes>
        <packageUrl regex="true">^pkg:pypi/urllib3@.*$</packageUrl>
        <cve>CVE-2023-XXXXX</cve>
    </suppress>
</suppressions>
EOF

echo "Suppression file example created. Use with: --suppression example-suppression.xml"
```{{exec}}

## CI/CD Integration Options

Key options used in CI:

- `--failOnCVSS 7.0` fail pipeline on high/critical issues (CVSS ≥ 7.0)
- `--format HTML,JSON,SARIF` produce rich reports for different tools
- `--out reports/dependency-check` save artifacts for review
- `--suppression suppressions.xml` ignore known false positives

## Easter Egg Clue #2 🔍

Looking at the dependency scan results, notice that some of the vulnerable packages we're using are related to serialization and cryptography. Combined with the hardcoded secret key from the SAST scan, this creates an interesting attack chain. The admin endpoints might be more accessible than they appear...

*Keep track of the vulnerable packages - you'll need them for the final Easter egg reveal!*

## What to observe

Review your scan results and consider:
- **Which packages are most risky?** Look for CVSS scores > 7.0
- **Are there direct upgrades** that fix issues without breaking changes?
- **Do transitive dependencies require constraints?** Sometimes you need to pin indirect dependencies
- **What's the security debt?** How many vulnerable packages vs. total packages

## Generating Comprehensive Reports

Let's create a summary report:

```bash
cat > dependency-summary.sh << 'EOF'
#!/bin/bash
echo "=== DEPENDENCY VULNERABILITY SUMMARY ==="
echo "Scan Date: $(date)"
echo "Project: VulnShop"
echo ""

if [ -f "dep-check-reports/dependency-check-report.json" ]; then
  TOTAL_DEPS=$(jq '.dependencies | length' dep-check-reports/dependency-check-report.json)
  VULNERABLE_DEPS=$(jq '[.dependencies[] | select(.vulnerabilities)] | length' dep-check-reports/dependency-check-report.json)
  TOTAL_VULNS=$(jq '[.dependencies[].vulnerabilities[]] | length' dep-check-reports/dependency-check-report.json 2>/dev/null || echo "0")
  CRITICAL=$(jq '[.dependencies[].vulnerabilities[] | select(.severity == "CRITICAL")] | length' dep-check-reports/dependency-check-report.json 2>/dev/null || echo "0")
  HIGH=$(jq '[.dependencies[].vulnerabilities[] | select(.severity == "HIGH")] | length' dep-check-reports/dependency-check-report.json 2>/dev/null || echo "0")
  MEDIUM=$(jq '[.dependencies[].vulnerabilities[] | select(.severity == "MEDIUM")] | length' dep-check-reports/dependency-check-report.json 2>/dev/null || echo "0")
  LOW=$(jq '[.dependencies[].vulnerabilities[] | select(.severity == "LOW")] | length' dep-check-reports/dependency-check-report.json 2>/dev/null || echo "0")
  
  echo "📊 STATISTICS:"
  echo "Total Dependencies: $TOTAL_DEPS"
  echo "Vulnerable Dependencies: $VULNERABLE_DEPS"
  echo "Total Vulnerabilities: $TOTAL_VULNS"
  echo ""
  echo "🚨 BY SEVERITY:"
  echo "Critical: $CRITICAL"
  echo "High: $HIGH"
  echo "Medium: $MEDIUM"
  echo "Low: $LOW"
  echo ""
  echo "🎯 RISK ASSESSMENT:"
  if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
    echo "Risk Level: HIGH - Immediate action required"
  elif [ "$MEDIUM" -gt 0 ]; then
    echo "Risk Level: MEDIUM - Schedule remediation"
  else
    echo "Risk Level: LOW - Monitor for updates"
  fi
fi
EOF

chmod +x dependency-summary.sh
./dependency-summary.sh
```{{exec}}

When done, run the verifier for this step:

```bash
./killerkoda-tutorial/step4-verify.sh
```{{exec}}
