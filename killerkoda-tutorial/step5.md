# Step 5: Container Image Scanning with Grype

In this step, you'll build the vulnerable application image and scan it for OS and package vulnerabilities using Grype.

## Understanding Container Security

Container images contain multiple layers of potential vulnerabilities:
- **Base OS vulnerabilities**: Issues in the underlying Linux distribution
- **System packages**: Vulnerabilities in installed system libraries
- **Application dependencies**: Issues in language-specific packages
- **Configuration issues**: Insecure container configurations

## Why Container Scanning Matters

- **Runtime vulnerabilities**: Issues that exist when your application runs
- **Supply chain security**: Vulnerabilities inherited from base images
- **Compliance requirements**: Many standards require container scanning
- **Attack surface reduction**: Identify and remove unnecessary components

## Installing Grype

First, let's install Grype, a powerful container vulnerability scanner:

```bash
cd devsecops-pipeline-tutorial
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
```{{exec}}

Verify the installation:
```bash
grype --version
```{{exec}}

## Examining the Dockerfile

Let's look at our application's Dockerfile to understand potential security issues:

```bash
cat vulnerable-app/Dockerfile
```{{exec}}

Notice potential security issues:
- **Base image**: May contain vulnerabilities
- **Running as root**: Security risk
- **Exposed ports**: Attack surface
- **Package installations**: May install vulnerable packages

## Build the Vulnerable Application Image

Let's build our container image:

```bash
cd vulnerable-app
docker build -t vulnshop:workshop .
```{{exec}}

Verify the image was built:
```bash
docker images | grep vulnshop
```{{exec}}

## Running Your First Container Scan

Let's scan the image for vulnerabilities:

```bash
cd ..
grype vulnshop:workshop --output json > grype-results.json
```{{exec}}

This will analyze all layers of the container image and identify vulnerabilities.

## Analyzing Container Scan Results

Let's examine what Grype found:

```bash
echo "=== CONTAINER VULNERABILITY SCAN RESULTS ==="
echo "Total vulnerabilities found: $(jq '.matches | length' grype-results.json)"
echo ""
echo "Vulnerabilities by severity:"
jq -r '.matches[].vulnerability.severity' grype-results.json | sort | uniq -c
```{{exec}}

## Understanding Vulnerability Details

Let's look at the most critical findings:

```bash
echo "=== HIGH/CRITICAL CONTAINER VULNERABILITIES ==="
jq -r '.matches[] | select(.vulnerability.severity == "High" or .vulnerability.severity == "Critical") | 
  "Package: \(.artifact.name)
  Version: \(.artifact.version)
  CVE: \(.vulnerability.id)
  Severity: \(.vulnerability.severity)
  Description: \(.vulnerability.description)
  Fix: \(.vulnerability.fix.versions[0] // "No fix available")
  ---"' grype-results.json | head -20
```{{exec}}

## Different Output Formats

Grype supports multiple output formats for different use cases:

```bash
# Human-readable table format
grype vulnshop:workshop --output table

# SARIF format for security tools
grype vulnshop:workshop --output sarif > grype-results.sarif

# Template format for custom reporting
grype vulnshop:workshop --output template -t grype-custom-template.tmpl
```{{exec}}

## Container Security Gates

Let's implement a security gate for container vulnerabilities:

```bash
cat > container-security-gate.sh << 'EOF'
#!/bin/bash
echo "=== CONTAINER SECURITY GATE ==="

if [ ! -f "grype-results.json" ]; then
  echo "[ERROR] No container scan results found"
  exit 1
fi

# Count high and critical vulnerabilities
HIGH_CRITICAL=$(jq '[.matches[] | select(.vulnerability.severity == "High" or .vulnerability.severity == "Critical")] | length' grype-results.json)
TOTAL=$(jq '.matches | length' grype-results.json)

echo "Total container vulnerabilities: $TOTAL"
echo "High/Critical vulnerabilities: $HIGH_CRITICAL"

# Define security gate threshold
THRESHOLD=0  # Zero tolerance for high/critical in production

if [ "$HIGH_CRITICAL" -gt "$THRESHOLD" ]; then
  echo "[FAIL] SECURITY GATE FAILED: $HIGH_CRITICAL high/critical vulnerabilities exceed threshold ($THRESHOLD)"
  echo ""
  echo "Most critical vulnerabilities:"
  jq -r '.matches[] | select(.vulnerability.severity == "High" or .vulnerability.severity == "Critical") | 
    "- \(.artifact.name) \(.artifact.version): \(.vulnerability.id) (\(.vulnerability.severity))"' grype-results.json | head -10
  echo ""
  echo "Action required: Update base image or vulnerable packages"
  exit 1
else
  echo "[PASS] SECURITY GATE PASSED: Container vulnerabilities within acceptable threshold"
fi
EOF

chmod +x container-security-gate.sh
./container-security-gate.sh
```{{exec}}

## Container Hardening Recommendations

Based on the scan results, here are common hardening strategies:

```bash
echo "=== CONTAINER SECURITY HARDENING GUIDE ==="
echo ""
echo "1. BASE IMAGE SECURITY:"
echo "   - Use minimal base images (alpine, distroless)"
echo "   - Regularly update base images"
echo "   - Use specific version tags, not 'latest'"
echo ""
echo "2. USER SECURITY:"
echo "   - Run as non-root user"
echo "   - Use USER directive in Dockerfile"
echo "   - Set appropriate file permissions"
echo ""
echo "3. PACKAGE MANAGEMENT:"
echo "   - Remove package managers after installation"
echo "   - Clean package caches"
echo "   - Install only necessary packages"
echo ""
echo "4. CONFIGURATION:"
echo "   - Use read-only filesystems where possible"
echo "   - Limit container capabilities"
echo "   - Use security contexts in Kubernetes"
```{{exec}}

## Creating a Secure Dockerfile

Let's create an improved version of our Dockerfile:

```bash
cat > vulnerable-app/Dockerfile.secure << 'EOF'
# Use specific version of minimal base image
FROM python:3.9-alpine3.18

# Create non-root user
RUN addgroup -g 1000 appgroup && \
    adduser -u 1000 -G appgroup -s /bin/sh -D appuser

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install dependencies and clean up
RUN pip install --no-cache-dir -r requirements.txt && \
    rm -rf /root/.cache

# Copy application code
COPY . .

# Change ownership to non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 5000

# Run application
CMD ["python", "run.py"]
EOF

echo "Secure Dockerfile created at vulnerable-app/Dockerfile.secure"
echo "Compare with original:"
echo "diff vulnerable-app/Dockerfile vulnerable-app/Dockerfile.secure"
```{{exec}}

## Advanced Grype Features

### 1. Scanning Specific Distros
```bash
# Scan for specific distro vulnerabilities
grype vulnshop:workshop --distro alpine:3.18
```{{exec}}

### 2. Filtering Results
```bash
# Only show fixable vulnerabilities
grype vulnshop:workshop --only-fixed

# Filter by severity
grype vulnshop:workshop --fail-on high
```{{exec}}

### 3. Configuration Files
```bash
cat > .grype.yml << 'EOF'
# Grype configuration file
ignore:
  # Ignore vulnerabilities by CVE
  - vulnerability: CVE-2023-XXXXX
    package:
      name: vulnerable-package
      version: "1.0.0"

# Only report high and critical
severity-cutoff: high

# Output configuration
output: json
file: grype-results.json
EOF

echo "Grype configuration created. Use with: grype vulnshop:workshop"
```{{exec}}

## CI behavior

In CI, the pipeline fails for `severity-cutoff: high`. This means any High or Critical vulnerability fails the job. Results are uploaded as SARIF and shown in the repository Security tab.

Let's simulate the CI behavior:

```bash
echo "=== CI/CD CONTAINER SCANNING SIMULATION ==="
echo "Running container scan with CI settings..."

# Simulate CI scan with failure on high/critical
if grype vulnshop:workshop --fail-on high --output json > ci-grype-results.json; then
  echo "[PASS] CI SCAN PASSED: No high/critical vulnerabilities"
else
  echo "[FAIL] CI SCAN FAILED: High/critical vulnerabilities detected"
  echo "Build would be blocked in CI/CD pipeline"
fi
```{{exec}}

## Container Security Metrics

Let's generate comprehensive metrics:

```bash
cat > container-security-metrics.sh << 'EOF'
#!/bin/bash
echo "=== CONTAINER SECURITY METRICS ==="
echo "Image: vulnshop:workshop"
echo "Scan Date: $(date)"
echo ""

if [ -f "grype-results.json" ]; then
  TOTAL=$(jq '.matches | length' grype-results.json)
  CRITICAL=$(jq '[.matches[] | select(.vulnerability.severity == "Critical")] | length' grype-results.json)
  HIGH=$(jq '[.matches[] | select(.vulnerability.severity == "High")] | length' grype-results.json)
  MEDIUM=$(jq '[.matches[] | select(.vulnerability.severity == "Medium")] | length' grype-results.json)
  LOW=$(jq '[.matches[] | select(.vulnerability.severity == "Low")] | length' grype-results.json)
  
  # Calculate risk score (Critical=10, High=7, Medium=4, Low=1)
  RISK_SCORE=$(echo "($CRITICAL * 10) + ($HIGH * 7) + ($MEDIUM * 4) + ($LOW * 1)" | bc 2>/dev/null || echo "0")
  
  echo "VULNERABILITY STATISTICS:"
  echo "Total: $TOTAL"
  echo "Critical: $CRITICAL"
  echo "High: $HIGH"
  echo "Medium: $MEDIUM"
  echo "Low: $LOW"
  echo ""
  echo "RISK ASSESSMENT:"
  echo "Risk Score: $RISK_SCORE"
  
  if [ "$CRITICAL" -gt 0 ]; then
    echo "Risk Level: CRITICAL - Immediate remediation required"
  elif [ "$HIGH" -gt 5 ]; then
    echo "Risk Level: HIGH - Schedule immediate remediation"
  elif [ "$HIGH" -gt 0 ] || [ "$MEDIUM" -gt 10 ]; then
    echo "Risk Level: MEDIUM - Plan remediation"
  else
    echo "Risk Level: LOW - Monitor and maintain"
  fi
  
  echo ""
  echo "TOP VULNERABLE PACKAGES:"
  jq -r '.matches[] | select(.vulnerability.severity == "Critical" or .vulnerability.severity == "High") | 
    "\(.artifact.name) \(.artifact.version) - \(.vulnerability.severity)"' grype-results.json | sort | uniq -c | sort -nr | head -5
fi
EOF

chmod +x container-security-metrics.sh
./container-security-metrics.sh
```{{exec}}

## Integration with Security Pipelines

Container scanning integrates with various security tools:

```bash
echo "=== CONTAINER SECURITY INTEGRATION ==="
echo ""
echo "CI/CD Integration:"
echo "- GitHub Actions: Upload SARIF results"
echo "- Jenkins: Parse JSON results for build gates"
echo "- GitLab: Native container scanning support"
echo ""
echo "Security Platform Integration:"
echo "- SARIF format for security dashboards"
echo "- JSON for custom reporting tools"
echo "- Webhook notifications for new vulnerabilities"
echo ""
echo "Monitoring Integration:"
echo "- Prometheus metrics from scan results"
echo "- Grafana dashboards for vulnerability trends"
echo "- Alert manager for critical findings"
```{{exec}}

When done, run the verifier for this step:

```bash
./killerkoda-tutorial/step5-verify.sh
```{{exec}}
