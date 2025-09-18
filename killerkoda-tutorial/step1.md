# Step 1: Environment Setup & DevSecOps Foundation

## Understanding DevSecOps

**DevSecOps** represents a fundamental shift from traditional software security approaches. Instead of treating security as a checkpoint at the end of development, DevSecOps integrates security practices, tools, and mindset throughout the entire development lifecycle.

### Traditional vs DevSecOps Security Model

**Traditional Security Approach:**
```
┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────┐
│ DEVELOP │→ │  BUILD  │→ │  TEST   │→ │ DEPLOY  │→ │ SECURITY    │
│         │  │         │  │         │  │         │  │ VALIDATION  │
└─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────────┘
                                                           ↑
                                                    Security Bottleneck
                                                    Late Detection
                                                    Expensive Fixes
```

**DevSecOps Approach:**
```
┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
│ DEVELOP │→ │  BUILD  │→ │  TEST   │→ │ DEPLOY  │
│    +    │  │    +    │  │    +    │  │    +    │
│Security │  │Security │  │Security │  │Security │
│Planning │  │Scanning │  │Testing  │  │Monitor  │
└─────────┘  └─────────┘  └─────────┘  └─────────┘
     ↓            ↓            ↓            ↓
┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
│  SAST   │  │Dependency│  │  DAST   │  │Runtime  │
│  Scan   │  │   Scan   │  │  Scan   │  │Security │
└─────────┘  └─────────┘  └─────────┘  └─────────┘
```

## Core DevSecOps Principles

### 1. Shift Security Left
Move security testing earlier in the development process where fixes are:
- **Faster to implement** (minutes vs weeks)
- **Less expensive** (10x-100x cost reduction)
- **Less disruptive** to development workflows

### 2. Automate Security Testing
Replace manual security reviews with:
- **Automated vulnerability scanning** integrated into CI/CD
- **Policy-as-code** for consistent security standards
- **Real-time feedback** to developers

### 3. Security as Code
Treat security configurations like application code:
- **Version controlled** security policies
- **Peer reviewed** security configurations
- **Tested and validated** security rules

## Three-Pillar Security Scanning Strategy

This tutorial implements comprehensive security coverage through three complementary scanning approaches:

### Pillar 1: Static Application Security Testing (SAST)
**What it detects:** Code-level vulnerabilities in source code
**Tool:** Semgrep
**Finds:** 
- SQL injection vulnerabilities
- Cross-site scripting (XSS) flaws
- Hardcoded secrets and credentials
- Insecure cryptographic implementations
- Authentication bypass vulnerabilities

### Pillar 2: Software Composition Analysis (SCA) / Dependency Scanning
**What it detects:** Vulnerabilities in third-party dependencies
**Tool:** OWASP Dependency Check
**Finds:**
- Known CVE vulnerabilities in libraries
- Outdated packages with security patches
- License compliance issues
- Transitive dependency vulnerabilities

### Pillar 3: Container Image Scanning
**What it detects:** Vulnerabilities in container images and runtime environments
**Tool:** Grype
**Finds:**
- Base image vulnerabilities
- Package-level vulnerabilities in containers
- Configuration security issues
- Runtime dependency vulnerabilities

## Environment Setup and Verification

Let's prepare your development environment with all necessary tools and dependencies.

### System Requirements Check

Verify your environment has the required foundations:

```bash
# Check Python installation
python3 --version
```{{exec}}

```bash
# Check Git availability
git --version
```{{exec}}

```bash
# Check Docker installation
docker --version
```{{exec}}

```bash
# Check system package manager
apt --version
```{{exec}}

### Security Tool Installation

Install the security scanning tools we'll use throughout this tutorial:

```bash
# Install Semgrep for Static Application Security Testing
pip3 install semgrep --break-system-packages
```{{exec}}

```bash
# Verify Semgrep installation
semgrep --version
```{{exec}}

```bash
# Install OWASP Dependency Check
wget -O dependency-check.zip https://github.com/jeremylong/DependencyCheck/releases/download/v8.4.0/dependency-check-8.4.0-release.zip
```{{exec}}

```bash
# Extract and set up Dependency Check
unzip dependency-check.zip && sudo mv dependency-check /opt/
sudo ln -sf /opt/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check
```{{exec}}

```bash
# Install Grype for container scanning
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
```{{exec}}

```bash
# Verify all security tools are installed
echo "=== SECURITY TOOLS VERIFICATION ==="
echo "Semgrep: $(semgrep --version | head -1)"
echo "Dependency Check: $(dependency-check --version 2>/dev/null | head -1 || echo 'Installed')"
echo "Grype: $(grype version | head -1)"
echo "All tools ready for DevSecOps implementation!"
```{{exec}}

### Project Repository Setup

Clone the vulnerable application repository that we'll secure throughout this tutorial:

```bash
# Clone the DevSecOps tutorial repository
git clone https://github.com/anica279p/devsecops-pipeline-tutorial.git
```{{exec}}

```bash
# Navigate to the project directory
cd devsecops-pipeline-tutorial
```{{exec}}

```bash
# Explore the project structure
echo "=== PROJECT STRUCTURE ==="
find . -type f -name "*.md" -o -name "*.yml" -o -name "*.py" -o -name "*.txt" | head -20
```{{exec}}

## Security Scanning Pipeline Overview

Before implementing individual tools, let's understand how they work together in a complete DevSecOps pipeline:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        AUTOMATED SECURITY PIPELINE                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐     ┌──────────────────────────────────────────┐          │
│  │ DEVELOPER   │────▶│           GIT REPOSITORY                  │          │
│  │ COMMITS     │     │         (GitHub)                          │          │
│  │ CODE        │     └──────────────────┬───────────────────────┘          │
│  └─────────────┘                        │                                   │
│                                         │ Webhook Trigger                   │
│                                         ▼                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    CI/CD PIPELINE (GitHub Actions)                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                         │                                   │
│              ┌──────────────────────────┼──────────────────────────┐        │
│              │                          │                          │        │
│              ▼                          ▼                          ▼        │
│    ┌─────────────────┐        ┌─────────────────┐        ┌─────────────────┐│
│    │ SAST SCANNING   │        │ DEPENDENCY SCAN │        │ CONTAINER SCAN  ││
│    │   (Semgrep)     │        │  (OWASP DC)     │        │    (Grype)      ││
│    │                 │        │                 │        │                 ││
│    │• Pattern Match  │        │• CVE Database   │        │• Image Layers   ││
│    │• Custom Rules   │        │• Package Vulns  │        │• Base OS Vulns  ││
│    │• Code Analysis  │        │• License Check  │        │• Package Vulns  ││
│    └─────────┬───────┘        └─────────┬───────┘        └─────────┬───────┘│
│              │                          │                          │        │
│              └──────────────────────────┼──────────────────────────┘        │
│                                         │                                   │
│                                         ▼                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    SECURITY GATE EVALUATION                         │   │
│  │                                                                     │   │
│  │  Critical vulnerabilities found?                                    │   │
│  │                                                                     │   │
│  │         ┌─────────────────┐           ┌─────────────────┐          │   │
│  │         │      YES        │           │       NO        │          │   │
│  │         │                 │           │                 │          │   │
│  │         ▼                 │           ▼                 │          │   │
│  │  ┌──────────────┐         │    ┌──────────────┐         │          │   │
│  │  │ FAIL BUILD   │         │    │ PASS BUILD   │         │          │   │
│  │  │ BLOCK DEPLOY │         │    │ CONTINUE     │         │          │   │
│  │  │ NOTIFY TEAM  │         │    │ DEPLOYMENT   │         │          │   │
│  │  └──────────────┘         │    └──────────────┘         │          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                         │                                   │
│                                         ▼                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    REPORTING & REMEDIATION                          │   │
│  │                                                                     │   │
│  │  • Detailed vulnerability reports                                   │   │
│  │  • Remediation guidance                                             │   │
│  │  • Security metrics and trends                                      │   │
│  │  • Compliance reporting                                             │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Key Security Concepts

Understanding these concepts will help you implement effective DevSecOps practices:

### CVSS (Common Vulnerability Scoring System)
A standardized method for rating security vulnerabilities:
- **0.0**: None
- **0.1-3.9**: Low severity
- **4.0-6.9**: Medium severity  
- **7.0-8.9**: High severity
- **9.0-10.0**: Critical severity

### CVE (Common Vulnerabilities and Exposures)
Unique identifiers for publicly disclosed security vulnerabilities. Example: CVE-2023-12345

### Security Gates
Automated checkpoints in CI/CD pipelines that:
- Evaluate security scan results
- Apply organization security policies
- Block deployments when criteria aren't met
- Provide immediate feedback to developers

### False Positives vs False Negatives
- **False Positive**: Tool reports a vulnerability that doesn't actually exist
- **False Negative**: Tool misses a real vulnerability
- **Tuning**: Process of adjusting tool configurations to minimize both

## Environment Validation

Verify your complete environment setup:

```bash
# Create a comprehensive environment check
echo "=== DEVSECOPS ENVIRONMENT VALIDATION ==="
echo ""
echo "📁 Project Structure:"
ls -la devsecops-pipeline-tutorial/
echo ""
echo "🔧 Security Tools:"
echo "  ✓ Semgrep: $(which semgrep > /dev/null && echo 'Ready' || echo 'Missing')"
echo "  ✓ Dependency Check: $(which dependency-check > /dev/null && echo 'Ready' || echo 'Missing')"
echo "  ✓ Grype: $(which grype > /dev/null && echo 'Ready' || echo 'Missing')"
echo ""
echo "🐳 Container Platform:"
echo "  ✓ Docker: $(docker --version | cut -d' ' -f3 | cut -d',' -f1)"
echo ""
echo "🔍 Ready for security scanning implementation!"
```{{exec}}

## Next Steps

With your environment properly configured, you're ready to:

1. **Explore the vulnerable application** and understand the security flaws we'll detect
2. **Implement SAST scanning** with Semgrep for code-level vulnerability detection
3. **Configure dependency scanning** to identify vulnerable third-party packages
4. **Set up container scanning** for comprehensive image security analysis
5. **Build the complete CI/CD pipeline** with automated security gates

Your DevSecOps foundation is now established. Let's move to Step 2 to explore the vulnerable application and identify the security issues our automated tools will detect.