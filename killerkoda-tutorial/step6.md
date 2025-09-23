# Step 6: CI/CD Pipeline Integration & Security Gates

In this step, you'll wire Semgrep, Dependency-Check, and Grype into CI/CD (e.g., GitHub Actions) and implement security gates to fail builds based on findings.

## Add a GitHub Actions workflow

```bash
mkdir -p .github/workflows
cat > .github/workflows/security-scan.yml << 'EOF'
name: Security Scans
on: [push, pull_request]
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install tools
        run: |
          pip install semgrep jq
          curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
          sudo apt-get update && sudo apt-get install -y default-jre unzip wget
          wget https://github.com/jeremylong/DependencyCheck/releases/download/v8.4.0/dependency-check-8.4.0-release.zip
          unzip -q dependency-check-8.4.0-release.zip
          echo "DEP_CHECK=./dependency-check/bin/dependency-check.sh" >> $GITHUB_ENV

      - name: Semgrep SAST
        run: |
          semgrep --config=.semgrep.yml --json vulnerable-app/ > semgrep-results.json || true
          test -s semgrep-results.json

      - name: Dependency-Check
        run: |
          $DEP_CHECK --project VulnShop --scan vulnerable-app/ --format "JSON" --out dep-check-reports --prettyPrint || true
          test -s dep-check-reports/dependency-check-report.json

      - name: Build image
        run: |
          docker build -t vulnshop:latest vulnerable-app

      - name: Grype image scan
        run: |
          grype vulnshop:latest -o json > grype-results.json || true
          test -s grype-results.json

      - name: Security gates
        run: |
          echo "Evaluate thresholds here (example only)"
          jq '.results | length' semgrep-results.json
          jq '.dependencies | length' dep-check-reports/dependency-check-report.json
          jq '.matches | length' grype-results.json
EOF
```{{exec}}

## Add example gate scripts (optional)

```bash
cat > security-gate-threshold.sh << 'EOF'
#!/bin/bash
set -e
file=${1:-semgrep-results.json}
limit=${2:-1}
count=$(jq '.results | length' "$file" 2>/dev/null || echo 0)
echo "Findings: $count (limit $limit)"
[ "$count" -le "$limit" ] || { echo "Gate failed"; exit 1; }
echo "Gate passed"
EOF
chmod +x security-gate-threshold.sh
```{{exec}}

When done, run the verifier for this step:

```bash
./killerkoda-tutorial/step6-verify.sh
```{{exec}}

# Step 6: CI/CD Pipeline Integration & Security Gates

## The Complete DevSecOps Pipeline

Now that you've learned to use all three security scanning tools individually, it's time to integrate them into an automated CI/CD pipeline. This is where DevSecOps really shines - every code change automatically triggers comprehensive security testing.

## Pipeline Architecture

Our complete security pipeline follows this flow:

```
┌─────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Code      │    │    Trigger       │    │   Checkout      │
│   Commit    ├────▶   CI/CD          ├────▶   Source Code   │
│             │    │   Pipeline       │    │                 │  
└─────────────┘    └──────────────────┘    └─────────┬───────┘
                                                     │
                                                     ▼
               ┌─────────────────────────────────────────────────┐
               │           SECURITY SCANNING PHASE               │
               │                                                 │
         ┌─────▼─────┐    ┌─────────▼─────────┐    ┌─────▼─────┐
         │   SAST    │    │   Dependency      │    │ Container │
         │ (Semgrep) │    │ Scan (OWASP DC)   │    │  (Grype)  │
         └─────┬─────┘    └─────────┬─────────┘    └─────┬─────┘
               │                    │                    │
               ▼                    ▼                    ▼
         ┌─────────────────────────────────────────────────────┐
         │              SECURITY GATE EVALUATION               │
         │                                                     │
         │  Critical vulnerabilities found?                    │
         │                                                     │
         │  ┌─────────┐              ┌─────────────┐           │
         │  │   YES   │              │     NO      │           │
         │  │         ▼              │             ▼           │
         │  │  ❌ FAIL BUILD         │  ✅ CONTINUE             │
         │  │  📧 NOTIFY TEAM        │  🚀 DEPLOY               │
         │  │  📊 GENERATE REPORT    │  📊 GENERATE REPORT     │
         └─────────────────────────────────────────────────────┘
```

## Examining the GitHub Actions Workflow

Let's look at the complete CI/CD workflow that's already configured in the repository:

```bash
cat .github/workflows/security-scan.yml
```{{exec}}

This workflow demonstrates several key DevSecOps principles:

### 1. Automated Triggers
The pipeline runs on every:
- Code push to main/develop branches
- Pull request creation
- Manual trigger

### 2. Parallel Security Scanning
All three security tools run in parallel for faster feedback:
```yaml
# SAST - Static Application Security Testing
- name: Run Semgrep SAST Scan
  run: semgrep --config=.semgrep.yml --json vulnerable-app/

# Dependency Scanning  
- name: Run OWASP Dependency Check
  run: dependency-check --project VulnShop --scan vulnerable-app/

# Container Scanning
- name: Run Grype Container Scan  
  run: grype vulnshop:latest --output json
```

### 3. Security Gate Logic
The pipeline evaluates findings and can fail the build:
```yaml
- name: Evaluate Security Gates
  run: |
    CRITICAL_COUNT=$(jq '[.results[] | select(.extra.severity=="ERROR")] | length' semgrep-report.json)
    if [ "$CRITICAL_COUNT" -gt 0 ]; then
      echo "SECURITY GATE FAILED"
      exit 1
    fi
```

## Implementing Security Gates

Security gates are automated decision points that determine whether code can proceed to the next stage. Let's implement different gate strategies:

### Strategy 1: Zero Tolerance (Strictest)
```bash
cat > security-gate-strict.sh << 'EOF'
#!/bin/bash
echo "=== STRICT SECURITY GATE ==="

# Any critical vulnerability fails the build
SEMGREP_CRITICAL=$(jq '[.results[] | select(.extra.severity=="ERROR")] | length' semgrep-results.json 2>/dev/null || echo "0")
DEP_HIGH=$(jq '.dependencies[]? | select(.vulnerabilities[]?.severity=="HIGH") | length' dep-check-results.json 2>/dev/null || echo "0")

TOTAL_CRITICAL=$((SEMGREP_CRITICAL + DEP_HIGH))

if [ "$TOTAL_CRITICAL" -gt 0 ]; then
    echo "BUILD FAILED: $TOTAL_CRITICAL critical vulnerabilities found"
    exit 1
else
    echo "BUILD PASSED: No critical vulnerabilities"
fi
EOF
```{{exec}}

### Strategy 2: Risk-Based Threshold
```bash
cat > security-gate-threshold.sh << 'EOF'
#!/bin/bash
echo "=== THRESHOLD-BASED SECURITY GATE ==="

# Allow up to 2 medium-risk findings, but no critical
CRITICAL_THRESHOLD=0
MEDIUM_THRESHOLD=2

SEMGREP_CRITICAL=$(jq '[.results[] | select(.extra.severity=="ERROR")] | length' semgrep-results.json 2>/dev/null || echo "0")
SEMGREP_MEDIUM=$(jq '[.results[] | select(.extra.severity=="WARNING")] | length' semgrep-results.json 2>/dev/null || echo "0")

echo "Critical findings: $SEMGREP_CRITICAL (threshold: $CRITICAL_THRESHOLD)"
echo "Medium findings: $SEMGREP_MEDIUM (threshold: $MEDIUM_THRESHOLD)"

if [ "$SEMGREP_CRITICAL" -gt "$CRITICAL_THRESHOLD" ]; then
    echo "BUILD FAILED: Critical vulnerabilities exceed threshold"
    exit 1
elif [ "$SEMGREP_MEDIUM" -gt "$MEDIUM_THRESHOLD" ]; then
    echo "BUILD FAILED: Medium vulnerabilities exceed threshold"  
    exit 1
else
    echo "BUILD PASSED: All findings within acceptable thresholds"
fi
EOF
```{{exec}}

### Strategy 3: Trend-Based (Advanced)
```bash
cat > security-gate-trend.sh << 'EOF'
#!/bin/bash
echo "=== TREND-BASED SECURITY GATE ==="

# Fail if security posture is getting worse
# (In practice, you'd compare against previous scan results)

CURRENT_ISSUES=$(jq '.results | length' semgrep-results.json 2>/dev/null || echo "0")
echo "Current scan: $CURRENT_ISSUES total issues"

# Simulate previous scan results for demo
PREVIOUS_ISSUES=3
echo "Previous scan: $PREVIOUS_ISSUES total issues"

if [ "$CURRENT_ISSUES" -gt "$PREVIOUS_ISSUES" ]; then
    echo "BUILD FAILED: Security posture degraded ($CURRENT_ISSUES vs $PREVIOUS_ISSUES)"
    echo "New vulnerabilities introduced - please review"
    exit 1
else
    echo "BUILD PASSED: Security posture maintained or improved"
fi
EOF
```{{exec}}

## Testing Security Gates Locally

Let's test our security gates with the actual scan results:

```bash
chmod +x security-gate-*.sh

echo "Testing with our vulnerable application results:"
echo ""
./security-gate-strict.sh
echo ""
./security-gate-threshold.sh  
echo ""
./security-gate-trend.sh
```{{exec}}

As expected, the strict gate fails because our application has critical vulnerabilities!

## CI/CD Integration Patterns

### Pattern 1: Branch Protection
```yaml
# In .github/workflows/security-scan.yml
on:
  pull_request:
    branches: [ main ]
    
# Require this check to pass before merging
jobs:
  security-scan:
    name: Security Vulnerability Scanning
    # This job must succeed for PR to be mergeable
```

### Pattern 2: Deployment Gates
```yaml
# Only deploy if security checks pass
deploy:
  needs: [security-scan]
  if: success()
  runs-on: ubuntu-latest
  steps:
    - name: Deploy to Production
      run: echo "Deploying secure application..."
```

### Pattern 3: Multi-Stage Pipeline
```bash
cat > multi-stage-pipeline.yml << 'EOF'
# Example multi-stage security pipeline
stages:
  - name: "Development Security Scan"
    trigger: "commit"
    tools: ["semgrep"]
    gate: "advisory"  # Report only, don't block
    
  - name: "Pre-Merge Security Scan"  
    trigger: "pull_request"
    tools: ["semgrep", "dependency-check"]
    gate: "blocking"  # Must pass to merge
    
  - name: "Pre-Deployment Security Scan"
    trigger: "merge_to_main"
    tools: ["semgrep", "dependency-check", "grype"]  
    gate: "strict"    # Zero tolerance for production
EOF

cat multi-stage-pipeline.yml
```{{exec}}

## Security Notification Integration

Configure notifications when security gates fail:

```bash
cat > notification-example.sh << 'EOF'
#!/bin/bash
# Example security notification logic

SCAN_RESULTS="semgrep-results.json"
CRITICAL_COUNT=$(jq '[.results[] | select(.extra.severity=="ERROR")] | length' $SCAN_RESULTS 2>/dev/null || echo "0")

if [ "$CRITICAL_COUNT" -gt 0 ]; then
    # In a real pipeline, send to Slack, email, or ticketing system
    echo "🚨 SECURITY ALERT 🚨"
    echo "Pipeline: DevSecOps Tutorial"
    echo "Repository: devsecops-pipeline-tutorial"
    echo "Critical Vulnerabilities: $CRITICAL_COUNT"
    echo ""
    echo "Top Issues:"
    jq -r '.results[] | select(.extra.severity=="ERROR") | "- \(.check_id): \(.path):\(.start.line)"' $SCAN_RESULTS
    echo ""
    echo "Action Required: Fix vulnerabilities before deployment"
fi
EOF

chmod +x notification-example.sh
./notification-example.sh
```{{exec}}

## Easter Egg Clue #3 🔍

The CI/CD pipeline configuration reveals something interesting. Look at the environment variables and secrets configuration. There's a special endpoint mentioned in the workflow comments that becomes accessible when certain conditions are met. The combination of the hardcoded secret key (from SAST), the vulnerable pickle deserialization (from SAST), and the admin authentication bypass might unlock something special...

Check the pipeline artifacts - there might be more than just security reports being generated!

## Monitoring and Metrics

DevSecOps pipelines should track security metrics over time:

```bash
cat > security-metrics.sh << 'EOF'
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
echo "- Total Vulnerabilities: $(jq '.results | length' semgrep-results.json 2>/dev/null || echo "N/A")"
echo "- Critical: $(jq '[.results[] | select(.extra.severity=="ERROR")] | length' semgrep-results.json 2>/dev/null || echo "N/A")"
echo "- High: 0"  # Would come from dependency/container scans
echo "- Medium: $(jq '[.results[] | select(.extra.severity=="WARNING")] | length' semgrep-results.json 2>/dev/null || echo "N/A")"
echo ""
echo "SECURITY GATE STATUS:"
echo "- Status: FAILED"
echo "- Reason: Critical vulnerabilities detected"
echo "- Action: Block deployment until fixed"
echo ""
echo "TRENDS:"
echo "- This Week: +$(jq '.results | length' semgrep-results.json) vulnerabilities detected"
echo "- Recommendation: Implement security training for development team"
EOF

chmod +x security-metrics.sh
./security-metrics.sh
```{{exec}}

## Best Practices for Security Gates

### 1. Start Permissive, Gradually Stricten
Begin with advisory-only scanning to avoid breaking existing workflows, then gradually implement blocking gates.

### 2. Different Gates for Different Stages
- **Development**: Fast feedback, advisory only
- **Pre-merge**: Comprehensive scanning, block on critical
- **Production**: Zero tolerance, full security validation

### 3. Provide Clear Remediation Guidance
When gates fail, provide developers with:
- Exact vulnerability locations
- Severity explanations  
- Fix recommendations
- Links to documentation

### 4. Regular Gate Calibration
Review and adjust security gate thresholds based on:
- Team security maturity
- Application risk profile
- Business requirements
- False positive rates

## Summary

You've now implemented a complete DevSecOps CI/CD pipeline with:

- **Automated security scanning** using three complementary tools
- **Flexible security gates** that can adapt to different risk tolerances  
- **Notification systems** for security failures
- **Metrics and monitoring** for continuous improvement
- **Integration patterns** for different development workflows

The final step will focus on security reporting and remediation strategies to make your DevSecOps implementation complete and actionable for development teams.