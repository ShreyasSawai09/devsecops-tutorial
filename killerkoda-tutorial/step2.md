# Step 2: Exploring the Vulnerable Application

## Understanding VulnShop

VulnShop is an intentionally vulnerable e-commerce web application built with Python Flask. It contains multiple security vulnerabilities across different categories, making it perfect for demonstrating automated security scanning tools.

Let's start the application and explore its vulnerabilities.

## Starting the Vulnerable Application

Navigate to the vulnerable application directory:
```bash
cd devsecops-pipeline-tutorial/vulnerable-app
```{{exec}}

Install the application dependencies:
```bash
pip3 install -r requirements.txt
```{{exec}}

Start the application:
```bash
python3 run.py
```{{exec}}

The application should now be running on port 5000. You can access it through the dashboard tab above or by visiting the application URL.

## Application Architecture

The VulnShop application consists of:

```
VulnShop Architecture
┌─────────────────────────────────────────────────────┐
│                 Web Interface                       │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │
│  │    Login    │ │  Dashboard  │ │   Search    │   │
│  │   (SQLi)    │ │   (Admin)   │ │   (SQLi)    │   │
│  └─────────────┘ └─────────────┘ └─────────────┘   │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│               Flask Application                     │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │
│  │   Profile   │ │File Upload  │ │   API       │   │
│  │   (IDOR)    │ │(Unrestricted│ │ (No Auth)   │   │
│  └─────────────┘ └─────────────┘ └─────────────┘   │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│              SQLite Database                        │
│         (Stores users and products)                 │
└─────────────────────────────────────────────────────┘
```

## Vulnerability Categories in VulnShop

Our application contains examples of the **OWASP Top 10** vulnerabilities:

### 1. Injection Vulnerabilities (SQL Injection)
**Location:** Login form (`/login`) and Search functionality (`/search`)
**Risk:** Attackers can bypass authentication and extract sensitive data

Test it:
- Try logging in with username: `' OR '1'='1' --`
- Search for: `' UNION SELECT username,password,email,role FROM users --`

### 2. Broken Authentication
**Location:** Hardcoded secret keys and weak session management
**Risk:** Session hijacking and unauthorized access

### 3. Sensitive Data Exposure
**Location:** API endpoints (`/api/user/{id}`) without authentication
**Risk:** Unauthorized access to user data

### 4. Insecure Direct Object References (IDOR)
**Location:** Profile page (`/profile?id=X`)  
**Risk:** Access to other users' profile information

### 5. Security Misconfiguration
**Location:** Flask debug mode enabled in production
**Risk:** Information disclosure and potential RCE

### 6. Cross-Site Scripting (XSS)
**Location:** Various input fields without proper sanitization
**Risk:** Account takeover and malicious script execution

### 7. Insecure Deserialization  
**Location:** Admin deserialize endpoint (`/deserialize`)
**Risk:** Remote code execution through malicious pickle data

### 8. Using Components with Known Vulnerabilities
**Location:** `requirements.txt` with outdated packages
**Risk:** Exploitation of known CVEs in dependencies

### 9. Insufficient Logging & Monitoring
**Location:** No security logging implemented
**Risk:** Undetected attacks and delayed incident response

### 10. Server-Side Request Forgery & Command Injection
**Location:** Admin command execution panel (`/execute`)
**Risk:** Remote code execution on the server

## Hands-On Vulnerability Testing

Let's explore some of these vulnerabilities hands-on. First, stop the current application with `Ctrl+C` and let's examine the source code:

```bash
# View the main application file
cat app.py | head -50
```{{exec}}

Notice the SQL injection vulnerability in the login function:
```bash
grep -A 5 -B 5 "SELECT.*FROM users WHERE" app.py
```{{exec}}

The dangerous line constructs SQL with string formatting:
```python
query = f"SELECT * FROM users WHERE username = '{username}' AND password = '{password}'"
```

This is exactly what SAST tools like Semgrep will detect!

## Dependencies with Known Vulnerabilities

Check the requirements.txt file:
```bash
cat requirements.txt
```{{exec}}

Notice the deliberately outdated packages:
- `urllib3==1.26.5` - Has known security vulnerabilities
- `setuptools==65.5.0` - Older version with potential issues  
- `requests==2.28.1` - Not the latest secure version

These vulnerable dependencies will be caught by OWASP Dependency Check.

## Container Security Issues

Examine the Dockerfile:
```bash
cat Dockerfile
```{{exec}}

Security issues in the container configuration:
- Running as root user
- No version pinning for some packages
- Exposing application on all interfaces (0.0.0.0)
- Debug mode enabled

These issues will be detected by Grype during container scanning.

## The Security Testing Challenge

Now you understand the application and its vulnerabilities. The challenge is:

**How do we automatically detect these security issues in a CI/CD pipeline?**

This is where our DevSecOps security scanning tools come in:

1. **Semgrep (SAST)** will find the SQL injection, command injection, and hardcoded secrets in the source code
2. **OWASP Dependency Check** will identify the vulnerable packages in requirements.txt  
3. **Grype** will scan the container image and find vulnerabilities in the base image and packages

## Easter Egg Hunt Begins! 🥚

**Secret Mission:** There's a hidden vulnerability in the application that requires combining insights from all three security scanning tools to fully understand and exploit. As you progress through the tutorial, look for clues about a special endpoint that might reveal something interesting when you know the right parameters...

*Hint: The clue is hidden in plain sight in one of the configuration files, but you'll need the scanning results to piece together the full picture.*

## Summary

You now understand:
- The structure and vulnerabilities in VulnShop
- How different vulnerability types manifest in real applications  
- Why manual security testing doesn't scale
- The types of issues each scanning tool will detect

In the next step, you'll implement your first automated security scanning tool: **Semgrep** for Static Application Security Testing (SAST).

Ready to start catching vulnerabilities automatically? Let's move to Step 3!