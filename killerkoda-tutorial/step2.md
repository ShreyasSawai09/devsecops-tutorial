# Step 2: Exploring the Vulnerable Application

## Introduction to VulnShop

VulnShop is an intentionally vulnerable e-commerce web application built with Python Flask. It contains multiple realistic security vulnerabilities that mirror real-world applications, making it an ideal target for demonstrating automated security scanning tools.

The application represents a typical web application stack with common architectural patterns and security anti-patterns that security scanners must detect.

## Application Architecture Analysis

Let's examine the application structure and understand its components:

```bash
# Navigate to the vulnerable application directory
cd vulnerable-app
```{{exec}}

```bash
# Examine the application structure
echo "=== VULNSHOP APPLICATION STRUCTURE ==="
tree . 2>/dev/null || find . -type f | head -20
```{{exec}}

### Core Application Components

```
VulnShop Architecture
┌─────────────────────────────────────────────────────────────┐
│                    WEB APPLICATION LAYER                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │   LOGIN     │ │  DASHBOARD  │ │   SEARCH    │           │
│  │ (SQL Inj)   │ │   (Admin)   │ │ (SQL Inj)   │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │  PROFILE    │ │FILE UPLOAD  │ │    API      │           │
│  │   (IDOR)    │ │(Unrestricted│ │ (No Auth)   │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
├─────────────────────────────────────────────────────────────┤
│                  APPLICATION LOGIC LAYER                    │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │   FLASK     │ │   PICKLE    │ │  COMMAND    │           │
│  │ FRAMEWORK   │ │DESERIALIZE  │ │ INJECTION   │           │
│  │(Debug Mode) │ │   (RCE)     │ │   (RCE)     │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
├─────────────────────────────────────────────────────────────┤
│                     DATA LAYER                              │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐   │
│  │              SQLite DATABASE                        │   │
│  │         (User credentials and product data)         │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Vulnerability Categories and Mapping

VulnShop implements examples from the **OWASP Top 10** vulnerability categories, providing comprehensive coverage for security scanning demonstrations.

### Critical Vulnerabilities (Immediate RCE Risk)

#### 1. SQL Injection (CWE-89)
**Location**: Login and Search functionality
**Impact**: Authentication bypass, data extraction, potential database compromise

```bash
# Examine the vulnerable SQL query construction
grep -n -A 3 -B 3 "SELECT.*FROM users WHERE" app.py
```{{exec}}

#### 2. Command Injection (CWE-78)
**Location**: Admin command execution panel
**Impact**: Remote code execution, system compromise

```bash
# Find the dangerous subprocess call
grep -n -A 5 -B 5 "subprocess.run" app.py
```{{exec}}

#### 3. Insecure Deserialization (CWE-502)
**Location**: Admin deserialize endpoint
**Impact**: Remote code execution via malicious pickle payloads

```bash
# Locate the pickle.loads vulnerability
grep -n -A 3 -B 3 "pickle.loads" app.py
```{{exec}}

### High-Risk Vulnerabilities

#### 4. Unrestricted File Upload (CWE-434)
**Location**: File upload functionality
**Impact**: Remote code execution via malicious file upload

```bash
# Check file upload security controls
grep -n -A 10 -B 5 "def upload_file" app.py
```{{exec}}

#### 5. Insecure Direct Object Reference - IDOR (CWE-639)
**Location**: Profile access functionality
**Impact**: Unauthorized data access, privacy violation

```bash
# Examine IDOR vulnerability in profile function
grep -n -A 8 -B 3 "def profile" app.py
```{{exec}}

### Medium-Risk Configuration Issues

#### 6. Hardcoded Secrets (CWE-798)
**Location**: Application configuration
**Impact**: Session hijacking, authentication bypass

```bash
# Find hardcoded secrets
grep -n "secret_key" app.py
```{{exec}}

#### 7. Debug Mode in Production (CWE-489)
**Location**: Flask application configuration
**Impact**: Information disclosure, potential code execution

```bash
# Check for debug mode configuration
grep -n "debug.*True" app.py run.py
```{{exec}}

## Dependency Vulnerability Analysis

Examine the application's dependencies for known security vulnerabilities:

```bash
# Review the requirements file for vulnerable packages
echo "=== DEPENDENCY ANALYSIS ==="
cat requirements.txt
```{{exec}}

### Known Vulnerable Dependencies

```bash
# Analyze specific vulnerable packages
echo "=== VULNERABLE DEPENDENCIES ANALYSIS ==="
echo ""
echo "1. urllib3==1.26.5 (Known CVEs)"
echo "   - CVE-2023-43804: Cookie request header vulnerability"
echo "   - CVE-2023-45803: Request body not stripped after redirect"
echo ""
echo "2. setuptools==65.5.0 (Potential vulnerabilities)"
echo "   - Older version may have undisclosed issues"
echo ""
echo "3. requests==2.28.1 (Not latest version)"
echo "   - May be missing security patches"
echo ""
echo "These will be detected by OWASP Dependency Check!"
```{{exec}}

## Container Security Analysis

Examine the container configuration for security issues:

```bash
# Analyze the Dockerfile for security misconfigurations
echo "=== CONTAINER SECURITY ANALYSIS ==="
cat Dockerfile
```{{exec}}

### Container Security Issues

```bash
echo "=== CONTAINER VULNERABILITIES ==="
echo ""
echo "1. Running as root user (Security Risk)"
echo "   - No USER directive to drop privileges"
echo ""
echo "2. Unrestricted network exposure"
echo "   - EXPOSE 5000 allows broad access"
echo ""
echo "3. Debug mode enabled in container"
echo "   - CMD runs with debug=True"
echo ""
echo "4. No version pinning for system packages"
echo "   - apt-get without specific versions"
echo ""
echo "These will be detected by Grype container scanning!"
```{{exec}}

## Application Environment Setup

Before we can run security scans, we need to set up the application environment properly:

### Python Environment Configuration

```bash
# Handle the externally-managed-environment issue in newer Ubuntu
echo "=== SETTING UP PYTHON ENVIRONMENT ==="
echo "Configuring Python environment for application dependencies..."
```{{exec}}

```bash
# Install application dependencies with proper flags
pip3 install -r requirements.txt --break-system-packages
```{{exec}}

### Application Initialization and Testing

```bash
# Initialize the application database
echo "=== INITIALIZING APPLICATION ==="
python3 -c "from app import init_db; init_db(); print('Database initialized successfully')"
```{{exec}}

```bash
# Test that the application can start (quick test)
echo "=== TESTING APPLICATION STARTUP ==="
timeout 5s python3 run.py &
sleep 2
curl -s http://localhost:5000 > /dev/null && echo "✓ Application starts successfully" || echo "⚠ Application startup test inconclusive"
```{{exec}}

## Vulnerability Discovery Exercise

Let's systematically identify the security issues that our automated tools will detect:

### Static Code Analysis Preview

```bash
# Count potential security issues manually
echo "=== MANUAL VULNERABILITY DISCOVERY ==="
echo ""
echo "SQL Injection patterns:"
grep -c "SELECT.*%" app.py
echo ""
echo "Command execution patterns:"
grep -c "subprocess\|system\|exec" app.py
echo ""
echo "Hardcoded secrets:"
grep -c "secret.*=" app.py
echo ""
echo "Debug configurations:"
grep -c "debug.*True" app.py run.py
```{{exec}}

### Security Scanning Preparation

```bash
# Verify our security tools are ready
echo "=== SECURITY TOOLS READINESS CHECK ==="
echo ""
echo "Semgrep (SAST): $(which semgrep >/dev/null && echo 'Ready' || echo 'Missing')"
echo "OWASP DC (SCA): $(which dependency-check >/dev/null && echo 'Ready' || echo 'Missing')"
echo "Grype (Container): $(which grype >/dev/null && echo 'Ready' || echo 'Missing')"
echo ""
echo "Application setup: Complete"
echo "Dependencies: Installed"
echo "Configuration files: Present"
```{{exec}}

## Vulnerability Summary Matrix

Based on our analysis, here's what each security tool should detect:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    VULNERABILITY DETECTION MATRIX                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐    │
│  │      SAST       │  │   DEPENDENCY    │  │   CONTAINER     │    │
│  │   (Semgrep)     │  │   (OWASP DC)    │  │    (Grype)      │    │
│  ├─────────────────┤  ├─────────────────┤  ├─────────────────┤    │
│  │ ✓ SQL Injection │  │ ✓ urllib3 CVEs  │  │ ✓ Base Image    │    │
│  │ ✓ Command Inj   │  │ ✓ setuptools    │  │ ✓ Package Vulns │    │
│  │ ✓ Hardcoded Key │  │ ✓ requests      │  │ ✓ Config Issues │    │
│  │ ✓ Pickle RCE    │  │ ✓ License Check │  │ ✓ Runtime Env   │    │
│  │ ✓ Debug Mode    │  │ ✓ Transitive    │  │ ✓ User Privs    │    │
│  │ ✓ Open Redirect │  │   Dependencies  │  │                 │    │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘    │
│                                                                     │
│  Expected Results: 6 findings    3 vulns        5+ issues          │
└─────────────────────────────────────────────────────────────────────┘
```

## Key Learning Outcomes

From this exploration, you now understand:

1. **Realistic vulnerability landscape** - VulnShop contains authentic security flaws found in production applications
2. **Multiple vulnerability categories** - From code-level issues to configuration problems
3. **Tool detection scope** - Each security tool targets specific vulnerability types
4. **Environment setup challenges** - Real-world deployment considerations
5. **Comprehensive scanning necessity** - No single tool catches all security issues

## Preparation Complete

Your vulnerable application environment is now ready for security scanning. You have:

- **Analyzed the application architecture** and identified key vulnerability categories
- **Set up the Python environment** with proper dependency handling
- **Explored specific vulnerabilities** that each security tool will detect
- **Prepared the scanning environment** with all necessary tools ready

In the next step, you'll implement Static Application Security Testing (SAST) with Semgrep to automatically detect the code-level vulnerabilities we've identified through manual analysis.

The foundation is set for comprehensive automated security scanning!