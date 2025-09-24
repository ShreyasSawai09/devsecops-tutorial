# Step 2: Exploring the Vulnerable Application

## Introduction to VulnShop

VulnShop is an intentionally vulnerable e-commerce web application built with Python Flask. It contains multiple realistic security vulnerabilities that mirror real-world applications, making it an ideal target for demonstrating automated security scanning tools.

**Why use an intentionally vulnerable application?** In the real world, you can't practice security scanning on production systems or other people's applications. VulnShop provides a safe, controlled environment where we can explore how security vulnerabilities manifest in code and how automated tools detect them.

The application represents a typical web application stack with common architectural patterns and security anti-patterns that security scanners must detect. Think of it as a "crash test dummy" for security tools - deliberately designed to showcase what can go wrong.

## Application Architecture Analysis

Before we can effectively use security scanning tools, we need to understand what we're scanning. Let's examine the application structure and understand its components:

Navigate to the vulnerable application directory:

```bash
cd vulnerable-app
```{{exec}}

Now let's explore the application structure to understand what files and components we're working with:

```bash
tree . 2>/dev/null || find . -type f | head -20
```{{exec}}

**What you should see:** A typical Python Flask application structure with files like `app.py` (main application), `requirements.txt` (dependencies), `Dockerfile` (container configuration), and various templates and static files.

**Tutorial Easter Egg Hunt:** It is always a good idea to read files that tell you to do so! 🕵️

### Core Application Components

Understanding the application architecture helps us anticipate what types of vulnerabilities might exist in each layer:

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

**What this shows:** VulnShop is structured like a typical web application, but each component has been intentionally designed with security flaws. The parenthetical notes (like "SQL Inj", "RCE") indicate the types of vulnerabilities present in each component.

## Vulnerability Categories and Mapping

VulnShop implements examples from the **OWASP Top 10** vulnerability categories, providing comprehensive coverage for security scanning demonstrations. Let's examine each category systematically:

### Critical Vulnerabilities (Immediate RCE Risk)

These vulnerabilities allow attackers to execute arbitrary code on the server, making them the highest priority security issues.

#### 1. SQL Injection (CWE-89)
**Location**: Login and Search functionality  
**Impact**: Authentication bypass, data extraction, potential database compromise

Let's examine how SQL injection vulnerabilities appear in the code:

```bash
grep -n -A 3 -B 3 "SELECT.*FROM users WHERE" app.py
```{{exec}}

**What you should see:** SQL queries that directly concatenate user input into the query string without proper parameterization. This is the classic SQL injection anti-pattern.

**What this means:** An attacker can inject malicious SQL code through login forms or search boxes to bypass authentication or extract sensitive data.

#### 2. Command Injection (CWE-78)
**Location**: Admin command execution panel  
**Impact**: Remote code execution, system compromise

Let's find the dangerous subprocess call that allows command injection:

```bash
grep -n -A 5 -B 5 "subprocess.run" app.py
```{{exec}}

**What you should see:** Code that passes user input directly to system commands without proper sanitization or validation.

**What this means:** An attacker with admin access could execute arbitrary system commands on the server, potentially taking complete control of the system.

#### 3. Insecure Deserialization (CWE-502)
**Location**: Admin deserialize endpoint  
**Impact**: Remote code execution via malicious pickle payloads

Let's locate the pickle.loads vulnerability:

```bash
grep -n -A 3 -B 3 "pickle.loads" app.py
```{{exec}}

**What you should see:** Code that deserializes data using Python's pickle module without proper validation.

**What this means:** Python's pickle module can execute arbitrary code during deserialization. An attacker can craft malicious pickle payloads that execute commands when processed.

### High-Risk Vulnerabilities

These vulnerabilities can lead to significant security breaches but may require additional steps or conditions to exploit.

#### 4. Unrestricted File Upload (CWE-434)
**Location**: File upload functionality  
**Impact**: Remote code execution via malicious file upload

Let's check what file upload security controls exist (or don't exist):

```bash
grep -n -A 10 -B 5 "def upload_file" app.py
```{{exec}}

**What you should see:** File upload functionality that doesn't properly validate file types, extensions, or content.

**What this means:** An attacker could upload executable files (like PHP scripts or Python code) that could then be executed on the server.

#### 5. Insecure Direct Object Reference - IDOR (CWE-639)
**Location**: Profile access functionality  
**Impact**: Unauthorized data access, privacy violation

Let's examine the IDOR vulnerability in the profile function:

```bash
grep -n -A 8 -B 3 "def profile" app.py
```{{exec}}

**What you should see:** Profile access that uses user-supplied IDs without verifying that the current user has permission to access that specific profile.

**What this means:** An attacker could access other users' profiles by simply changing user IDs in the URL, violating user privacy and data protection.

### Medium-Risk Configuration Issues

These issues may not directly lead to code execution but create significant security weaknesses.

#### 6. Hardcoded Secrets (CWE-798)
**Location**: Application configuration  
**Impact**: Session hijacking, authentication bypass

Let's find hardcoded secrets in the application:

```bash
grep -n "secret_key" app.py
```{{exec}}

**What you should see:** Secret keys, passwords, or API tokens hardcoded directly in the source code.

**What this means:** Anyone with access to the source code (including public repositories) can see these secrets and potentially compromise the application.

#### 7. Debug Mode in Production (CWE-489)
**Location**: Flask application configuration  
**Impact**: Information disclosure, potential code execution

Let's check for debug mode configuration:

```bash
grep -n "debug.*True" app.py run.py
```{{exec}}

**What you should see:** Flask applications configured to run in debug mode, which exposes detailed error messages and potentially interactive debugging interfaces.

**What this means:** Debug mode can reveal sensitive information about the application structure and potentially allow code execution through debug interfaces.

## Application Environment Setup

Before we can run security scans, we need to set up the application environment properly. This step simulates the environment preparation that would happen in a real CI/CD pipeline:

### Python Environment Configuration

Let's install the application dependencies. In a real environment, this would typically happen during the build process:

```bash
pip3 install -r requirements.txt --break-system-packages
```{{exec}}

**What this command does:** Installs all the Python packages listed in requirements.txt, including the vulnerable versions we identified earlier. The `--break-system-packages` flag is needed in some environments to allow installation.

If there was an error during installation, let's try installing Flask specifically:

```bash
pip3 install --user flask --break-system-packages
```{{exec}}

**Why we might need this:** Sometimes package installation fails due to dependency conflicts or environment restrictions. This fallback ensures Flask (our main framework) is available.

### Application Initialization and Testing

Now let's initialize the application database and test that everything works:

```bash
python3 -c "from app import init_db; init_db(); print('Database initialized successfully')"
```{{exec}}

**What you should see:** A success message indicating the database was created and initialized with sample data.

**What this does:** Creates the SQLite database and populates it with initial data (users, products, etc.) that our security scans will interact with.

Let's verify the application can start correctly:

```bash
timeout 5s python3 run.py &
sleep 2
curl -s http://localhost:5000 > /dev/null && echo "✓ Application starts successfully" || echo "⚠ Application startup test inconclusive"
```{{exec}}

**What this does:** Starts the application briefly and tests if it responds to HTTP requests. This confirms our environment setup is working correctly.

**What you should see:** Either a success message indicating the app starts correctly, or a note that the test was inconclusive (which is fine - we're just doing a quick check).

## Vulnerability Discovery Exercise

Before we rely on automated tools, let's do some manual vulnerability discovery. This helps us understand what the automated tools should find and gives us a baseline for comparison.

### Static Code Analysis Preview

Let's systematically count potential security issues that we can identify manually:

First, let's look for SQL Injection patterns:

```bash
echo "Counting SQL injection patterns:"
grep -c "SELECT.*%" app.py
```{{exec}}

**What you should see:** A count of SQL queries that use string formatting (the % operator), which is a common SQL injection anti-pattern.

Next, let's check for command execution patterns:

```bash
echo "Counting command execution patterns:"
grep -c "subprocess\|system\|exec" app.py
```{{exec}}

**What you should see:** The number of locations where the application executes system commands, which could be vulnerable to command injection.

Let's look for hardcoded secrets:

```bash
echo "Counting hardcoded secrets:"
grep -c "secret.*=" app.py
```{{exec}}

**What you should see:** The count of hardcoded secret values in the application.

And finally, debug configurations:

```bash
echo "Counting debug configurations:"
grep -c "debug.*True" app.py run.py
```{{exec}}

**What you should see:** The number of places where debug mode is enabled, which is dangerous in production.

## Key Learning Outcomes

From this exploration, you now understand:

1. **Realistic vulnerability landscape** - VulnShop contains authentic security flaws found in production applications, giving you hands-on experience with real-world security issues

2. **Multiple vulnerability categories** - Security issues exist at different layers: code vulnerabilities, dependency vulnerabilities, and container misconfigurations

3. **Tool detection scope** - Each security tool targets specific vulnerability types, and comprehensive security requires multiple complementary scanning approaches

4. **Environment setup challenges** - Real-world deployment considerations like dependency management and application initialization that affect security scanning

5. **Comprehensive scanning necessity** - No single tool catches all security issues; effective DevSecOps requires multiple layers of security scanning

6. **Manual vs. automated analysis** - Understanding how to manually identify vulnerabilities helps you better interpret and validate automated tool results

## Preparation Complete

Your vulnerable application environment is now ready for comprehensive security scanning. You have:

- **✅ Analyzed the application architecture** and identified key vulnerability categories across all layers
- **✅ Set up the Python environment** with proper dependency handling and initialization procedures  
- **✅ Explored specific vulnerabilities** that each security tool will detect, giving you baseline expectations
- **✅ Prepared the scanning environment** with verification that all necessary tools are available
- **✅ Created a vulnerability detection matrix** that shows how different tools complement each other

**What's Next:** In the next step, you'll implement Static Application Security Testing (SAST) with Semgrep to automatically detect the code-level vulnerabilities we've identified through manual analysis. You'll see how automated tools can quickly and consistently find security issues that would take much longer to discover manually.

The foundation is set for comprehensive automated security scanning that will transform your understanding of DevSecOps in practice!