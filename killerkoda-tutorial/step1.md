# Step 1: DevSecOps Fundamentals & Environment Setup

## Understanding DevSecOps

**DevSecOps** extends the DevOps methodology by integrating security practices throughout the software development lifecycle. Instead of treating security as a gate at the end of development, DevSecOps embeds security controls, testing, and monitoring into every stage.

### Traditional vs DevSecOps Security Approach

**Traditional Approach:**
```
Develop → Build → Test → Deploy → [Security Check] → Production
                                    ^
                              Security bottleneck
```

**DevSecOps Approach:**
```
Develop → Build → Test → Deploy → Production
   ↓        ↓      ↓        ↓
Security  SAST   Dep.   Container
Planning  Scan   Check   Scanning
```

### Core DevSecOps Principles

1. **Shift Security Left** - Address security concerns early in development
2. **Automate Security Testing** - Remove human bottlenecks from security processes
3. **Continuous Monitoring** - Monitor applications and infrastructure continuously
4. **Shared Responsibility** - Security is everyone's responsibility, not just security teams
5. **Fail Fast** - Catch vulnerabilities before they reach production

## Three Pillars of Automated Security Scanning

In this tutorial, we'll implement the three essential types of automated security scanning:

### Static Application Security Testing (SAST)
- **What:** Analyzes source code to find security vulnerabilities
- **Tool:** Semgrep
- **Finds:** SQL injection, XSS, hardcoded secrets, insecure crypto
- **When:** During code commit/build process

### Dependency Vulnerability Scanning  
- **What:** Scans third-party libraries and packages for known vulnerabilities
- **Tool:** OWASP Dependency Check
- **Finds:** Vulnerable packages with published CVEs
- **When:** During build process and continuously

### Container Image Scanning
- **What:** Scans container images for vulnerabilities in OS and application layers
- **Tool:** Grype
- **Finds:** Vulnerable base images, packages, and binaries
- **When:** During image build and before deployment

## Environment Verification

Let's verify your environment is properly set up for this tutorial.

Check that Python is installed:
```bash
python3 --version
```{{exec}}

Verify Git is available:
```bash
git --version
```{{exec}}

Check Docker installation:
```bash
docker --version
```{{exec}}

Install required Python packages:
```bash
pip3 install --upgrade pip
```{{exec}}

## Clone the Vulnerable Application

For this tutorial, we'll use **VulnShop**, an intentionally vulnerable e-commerce application that contains multiple security flaws across different categories.

Clone the repository:
```bash
git clone https://github.com/anica279p/devsecops-pipeline-tutorial.git
cd devsecops-pipeline-tutorial
```{{exec}}

Explore the project structure:
```bash
ls -la
```{{exec}}

```bash
tree vulnerable-app/ || find vulnerable-app/ -type f
```{{exec}}

## Understanding the Security Testing Pipeline

Before we dive into implementing security tools, let's understand the complete pipeline we'll be building:

```
┌─────────────────┐
│ Developer       │
│ Commits Code    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐    ┌─────────────────┐
│ Git Repository  │───▶│ CI/CD Pipeline  │
│ (GitHub)        │    │ Triggers        │
└─────────────────┘    └─────────┬───────┘
                                 │
                                 ▼
          ┌──────────────────────┴──────────────────────┐
          │              Security Scanning              │
          │                                             │
    ┌─────▼─────┐  ┌─────────▼─────────┐  ┌─────▼─────┐
    │   SAST    │  │   Dependency      │  │ Container │
    │ (Semgrep) │  │ Scan (OWASP DC)   │  │   (Grype) │
    └─────┬─────┘  └─────────┬─────────┘  └─────┬─────┘
          │                  │                  │
          ▼                  ▼                  ▼
    ┌─────────────────────────┴──────────────────────┐
    │            Security Gate Evaluation            │
    │                                                │
    │ Critical vulns found? ──┬─► YES ─► FAIL BUILD  │
    │                         │                      │
    │                         └─► NO  ─► CONTINUE    │
    └─────────────────────────┬──────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ Generate        │
                    │ Security        │
                    │ Reports         │
                    └─────────────────┘
```

For a detailed view of the complete pipeline architecture, see the [Pipeline Diagram](./assets/pipeline-diagram.txt).

## Key Security Concepts

**CVSS (Common Vulnerability Scoring System):** A standard for rating vulnerability severity from 0-10
- 0.0: None  
- 0.1-3.9: Low
- 4.0-6.9: Medium
- 7.0-8.9: High
- 9.0-10.0: Critical

**CVE (Common Vulnerabilities and Exposures):** Unique identifiers for publicly known security vulnerabilities

**Security Gate:** Automated checks that can fail a build/deployment if security criteria aren't met

## Next Steps

In the following steps, you will:
1. **Explore the vulnerable application** and understand the security flaws we need to detect
2. **Implement SAST scanning** with Semgrep to find code-level vulnerabilities  
3. **Configure dependency scanning** to identify vulnerable third-party packages
4. **Set up container scanning** to secure your application images
5. **Build an automated CI/CD pipeline** that runs all security checks
6. **Create security reporting** that provides actionable insights

Your environment is now ready. Let's move to Step 2 to explore the vulnerable application and see what security issues we'll be detecting!
=======
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

Check Python installation
```bash
python3 --version
```{{exec}}

Check Git availability
```bash
git --version
```{{exec}}

Check Docker installation
```bash
docker --version
```{{exec}}

Check system package manager
```bash
apt --version
```{{exec}}

### Security Tool Installation

Install the security scanning tools we'll use throughout this tutorial:

Install Semgrep for Static Application Security Testing
```bash
pip3 install --user semgrep --break-system-packages
```{{exec}}

Add Semgrep to PATH and make it permanent
```bash
export PATH="/root/.local/bin:$PATH"
echo 'export PATH="/root/.local/bin:$PATH"' >> ~/.bashrc
```{{exec}}

Verify Semgrep installation
```bash
semgrep --version
```{{exec}}

Install OWASP Dependency Check
```bash
wget -O dependency-check.zip https://github.com/jeremylong/DependencyCheck/releases/download/v8.4.0/dependency-check-8.4.0-release.zip
```{{exec}}

Extract and set up Dependency Check
```bash
unzip dependency-check.zip && sudo mv dependency-check /opt/
```{{exec}}

```bash
sudo ln -sf /opt/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check
```{{exec}}

Install Grype for container scanning
```bash
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
```{{exec}}

Verify all security tools are installed
```bash
echo "Semgrep: $(semgrep --version | head -1)"
echo "Dependency Check: $(dependency-check --version 2>/dev/null | head -1 || echo 'Installed')"
echo "Grype: $(grype version | head -1)"
```{{exec}}

### Project Repository Setup

Clone the vulnerable application repository that we'll investigate throughout this tutorial:

Clone the DevSecOps tutorial repository
```bash
git clone https://github.com/anica279p/devsecops-pipeline-tutorial.git
```{{exec}}

Navigate to the project directory
```bash
cd devsecops-pipeline-tutorial
```{{exec}}

Explore the project structure
```bash
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

Check project structure:
```bash
ls -la
```{{exec}}

Verify Semgrep installation:
```bash
echo "  ✓ Semgrep: $(which semgrep > /dev/null && echo 'Ready' || echo 'Missing')"
```{{exec}}

Verify OWASP Dependency Check installation:
```bash
echo "  ✓ Dependency Check: $(which dependency-check > /dev/null && echo 'Ready' || echo 'Missing')"
```{{exec}}

Verify Grype installation:
```bash
echo "  ✓ Grype: $(which grype > /dev/null && echo 'Ready' || echo 'Missing')"
```{{exec}}

Check Docker availability:
```bash
echo "  ✓ Docker: $(docker --version | cut -d' ' -f3 | cut -d',' -f1)"
```{{exec}}

## Next Steps

With your environment properly configured, you're ready to:

1. **Explore the vulnerable application** and understand the security flaws we'll detect
2. **Implement SAST scanning** with Semgrep for code-level vulnerability detection
3. **Configure dependency scanning** to identify vulnerable third-party packages
4. **Set up container scanning** for comprehensive image security analysis
5. **Build the complete CI/CD pipeline** with automated security gates

Your DevSecOps foundation is now established. Let's move to Step 2 to explore the vulnerable application and identify the security issues our automated tools will detect.
