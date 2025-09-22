# DevSecOps Pipeline Tutorial

A comprehensive hands-on tutorial for implementing automated security scanning in CI/CD pipelines using SAST, dependency scanning, and container scanning.

## Project Overview

This repository contains:
- **VulnShop**: An intentionally vulnerable Flask web application for security testing
- **Complete DevSecOps Tutorial**: Step-by-step KillerKoda tutorial implementation
- **CI/CD Security Pipeline**: Automated GitHub Actions workflow with security scanning
- **Educational Content**: Comprehensive learning materials for DevSecOps practices

## Repository Structure

```
devsecops-pipeline-tutorial/
├── vulnerable-app/              # Intentionally vulnerable Flask application
│   ├── app.py                  # Main application with security vulnerabilities
│   ├── requirements.txt        # Dependencies (including vulnerable packages)
│   ├── Dockerfile             # Container configuration
│   └── templates/             # HTML templates
├── killerkoda-tutorial/        # Complete KillerKoda tutorial content
│   ├── index.json             # Scenario configuration
│   ├── setup.sh              # Environment setup script
│   ├── intro.md              # Tutorial introduction
│   ├── step1.md - step7.md   # Tutorial steps
│   ├── finish.md             # Conclusion
│   └── *-verify.sh           # Step verification scripts
├── .github/workflows/          # CI/CD pipeline configuration
│   └── security-scans.yml     # Automated security scanning workflow (OWASP DC + Grype)
├── .semgrep.yml               # Semgrep SAST configuration
├── .grype.yaml                # Grype container scanner configuration
└── dependency-check.properties # OWASP Dependency Check configuration
```

## Quick Start

### Running the Vulnerable Application

```bash
cd vulnerable-app
pip install -r requirements.txt
python run.py
```

Access the application at http://localhost:5000

**Test Accounts:**
- Admin: `admin` / `admin123`
- User: `user` / `password`

### Running Security Scans Locally

```bash
# SAST with Semgrep
pip install semgrep
semgrep --config=.semgrep.yml vulnerable-app/

# Dependency scanning
dependency-check --project VulnShop --scan vulnerable-app/

# Container scanning
docker build -t vulnshop vulnerable-app/
grype vulnshop
```

## Tutorial Content

The KillerKoda tutorial covers:

1. **DevSecOps Fundamentals** - Understanding security-first development
2. **Vulnerable Application Exploration** - Hands-on security testing
3. **Static Application Security Testing (SAST)** - Code-level vulnerability detection
4. **Dependency Vulnerability Scanning** - Third-party package security
5. **Container Image Scanning** - Docker image vulnerability assessment
6. **CI/CD Pipeline Integration** - Automated security testing workflows
7. **Security Reporting & Remediation** - Actionable security insights

**Duration:** 45-60 minutes  
**Level:** Intermediate  
**Prerequisites:** Basic knowledge of Git, Docker, and CI/CD concepts

## Security Vulnerabilities Included

The VulnShop application contains intentional vulnerabilities for educational purposes:

- **SQL Injection** - Authentication bypass and data extraction
- **Command Injection** - Remote code execution via admin panel
- **Insecure File Upload** - Unrestricted file upload leading to RCE
- **Insecure Direct Object Reference (IDOR)** - Unauthorized data access
- **Hardcoded Secrets** - API keys and secrets in source code
- **Insecure Deserialization** - Remote code execution via pickle
- **Debug Mode Enabled** - Information disclosure in production
- **Vulnerable Dependencies** - Known CVEs in third-party packages

## CI/CD Security Pipeline

The automated pipeline includes:

- **Parallel Security Scanning** - SAST, dependency, and container scans
- **Security Gates** - Automated build failure on critical findings
- **Comprehensive Reporting** - Detailed vulnerability analysis
- **Artifact Generation** - Downloadable security reports

### GitHub Actions Workflow

Status badges (enabled after first run on default branch):

![Security Scans](https://github.com/anica279p/devsecops-pipeline-tutorial/actions/workflows/security-scans.yml/badge.svg)

Key configurations:
- OWASP Dependency-Check: `--failOnCVSS 7.0`, outputs HTML/JSON/SARIF under `reports/dependency-check/`
- Grype: `severity-cutoff: high`, SARIF uploaded to the Security tab

## Educational Goals

Students learn to:
- Implement DevSecOps methodology in real projects
- Configure and customize security scanning tools
- Build automated CI/CD security pipelines
- Create actionable security reports for different audiences
- Establish security gates and remediation workflows

## Tools Demonstrated

- **Semgrep** - Static Application Security Testing (SAST)
- **OWASP Dependency Check** - Dependency vulnerability scanning
- **Grype** - Container image security scanning
- **GitHub Actions** - CI/CD pipeline automation

## Warning

This application is **intentionally vulnerable** and should **NEVER** be deployed in a production environment. It is designed solely for educational and security testing purposes in controlled environments.

## Contributing

This tutorial was developed as part of a DevOps course assignment. Contributions that improve the educational value or fix issues are welcome.

## License

Educational use only - not for production deployment.

## Authors

- Anica Krüger (anicak@kth.se)
- Shreyas Sawai (sawai@kth.se)

Course: Automated Software Testing & DevOps (DD2482) - KTH Royal Institute of Technology