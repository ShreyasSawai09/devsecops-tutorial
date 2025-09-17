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