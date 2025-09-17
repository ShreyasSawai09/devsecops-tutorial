# VulnShop - Intentionally Vulnerable E-commerce Application

![VulnShop Logo](https://img.shields.io/badge/VulnShop-Intentionally%20Vulnerable-red?style=for-the-badge)
![Python](https://img.shields.io/badge/Python-3.9+-blue?style=flat-square)
![Flask](https://img.shields.io/badge/Flask-2.3.2-green?style=flat-square)
![License](https://img.shields.io/badge/License-Educational%20Use%20Only-orange?style=flat-square)

## ⚠️ WARNING

**This application is intentionally vulnerable and should NEVER be deployed in a production environment.**

This is an educational tool designed for DevSecOps training and security testing purposes only.

## 🎯 Purpose

VulnShop is designed as the foundation for a comprehensive DevSecOps tutorial that demonstrates:

- **Static Application Security Testing (SAST)** with Semgrep
- **Dependency vulnerability scanning** with OWASP Dependency Check  
- **Container image scanning** with Grype
- **CI/CD security pipeline integration**
- **Automated security reporting and gates**

## 🐛 Included Vulnerabilities

| Vulnerability Type | Location | Description |
|-------------------|----------|-------------|
| **SQL Injection** | Login & Search | Unparameterized queries allowing data extraction |
| **Command Injection** | Admin Panel | Direct system command execution |
| **File Upload** | Upload Page | Unrestricted file upload enabling RCE |
| **IDOR** | Profile Page | Access other users' data via ID manipulation |
| **Insecure Deserialization** | Admin API | Pickle deserialization of user input |
| **Open Redirect** | Redirect endpoint | Unvalidated redirect parameter |
| **Hardcoded Secrets** | Source Code | API keys and secrets in code |
| **Vulnerable Dependencies** | requirements.txt | Outdated packages with known CVEs |
| **Missing Authentication** | API endpoints | Sensitive data exposure |
| **Debug Mode** | Flask Config | Production debugging enabled |

## 🚀 Quick Start

### Prerequisites

- Python 3.9 or higher
- pip package manager

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd vulnerable-app
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Run the application:**
   ```bash
   python run.py
   ```

4. **Access the application:**
   Open your browser and navigate to `http://localhost:5000`

## 👥 Test Accounts

| Username | Password | Role | Description |
|----------|----------|------|-------------|
| `admin` | `admin123` | Administrator | Full access including command execution |
| `user` | `password` | Regular User | Standard user access |

## 🌐 Key Endpoints

### Web Interface
- **/** - Home page with vulnerability overview
- **/login** - Vulnerable login form (SQL injection)
- **/search** - Product search (SQL injection)  
- **/profile** - User profile (IDOR vulnerability)
- **/upload** - File upload (unrestricted upload)
- **/dashboard** - User dashboard with admin features

### API Endpoints
- **GET /api/user/{id}** - User information (no authentication)
- **POST /execute** - Command execution (admin only)
- **POST /deserialize** - Insecure deserialization (admin only)
- **GET /redirect?url=** - Open redirect vulnerability

## 🔧 Vulnerability Examples

### SQL Injection
```sql
# Login bypass
Username: ' OR '1'='1' --
Password: anything

# Data extraction via search
Search: ' UNION SELECT 1,username,password,email FROM users --
```

### Command Injection (Admin required)
```bash
# Execute system commands
ls -la
whoami
cat /etc/passwd
```

### File Upload
Upload malicious files like:
- `shell.php` - PHP web shell
- `shell.jsp` - JSP web shell
- `.htaccess` - Apache configuration override

### IDOR (Insecure Direct Object Reference)
```
# Access other users' profiles
/profile?id=1
/profile?id=2
/api/user/1
```

## 🏗️ Project Structure

```
vulnerable-app/
├── app.py                 # Main Flask application
├── run.py                 # Application runner with setup
├── requirements.txt       # Python dependencies (vulnerable versions)
├── Dockerfile            # Container configuration (vulnerable)
├── templates/            # HTML templates
│   ├── base.html         # Base template with styling
│   ├── index.html        # Home page
│   ├── login.html        # Login form
│   ├── dashboard.html    # User dashboard  
│   ├── search.html       # Search functionality
│   ├── profile.html      # User profile
│   └── upload.html       # File upload
├── uploads/              # File upload directory
└── vulnerable_app.db     # SQLite database (auto-created)
```

## 🔒 Security Features (Deliberately Missing)

This application deliberately lacks standard security controls:

- ❌ Input validation and sanitization
- ❌ Parameterized SQL queries  
- ❌ File type restrictions
- ❌ Authentication on API endpoints
- ❌ CSRF protection
- ❌ Secure session management
- ❌ Content Security Policy
- ❌ Rate limiting
- ❌ Logging and monitoring

## 🐳 Docker Usage

Build and run the vulnerable application in a container:

```bash
# Build the image
docker build -t vulnshop .

# Run the container
docker run -p 5000:5000 vulnshop
```

## 📚 Educational Use

This application is designed for:

- **Security training workshops**
- **DevSecOps pipeline demonstrations**
- **Vulnerability assessment practice**
- **Security tool testing and validation**
- **Penetration testing training**

## 🛡️ Remediation Examples

Each vulnerability includes examples of:
- How to identify the issue
- Impact assessment
- Remediation strategies
- Secure coding alternatives

## 📊 DevSecOps Integration

This application will be used to demonstrate:

1. **SAST Integration** - Semgrep rules for detecting code vulnerabilities
2. **Dependency Scanning** - OWASP Dependency Check for vulnerable packages
3. **Container Scanning** - Grype for container image vulnerabilities
4. **CI/CD Pipeline** - GitHub Actions with security gates
5. **Security Reporting** - Automated vulnerability reports
6. **Fail-Fast Principles** - Breaking builds on critical findings

## ⚖️ Legal Disclaimer

This software is provided for educational purposes only. Users are responsible for ensuring compliance with all applicable laws and regulations. The authors are not responsible for any misuse of this software.

## 🤝 Contributing

This is an educational project. Contributions that add new vulnerability types or improve the learning experience are welcome.

## 📄 License

Educational Use Only - Not for production deployment

---

**Remember: This application is intentionally vulnerable. Never deploy it in a production environment!**