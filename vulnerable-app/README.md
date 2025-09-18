# VulnShop - Intentionally Vulnerable E-commerce Application

A deliberately insecure Flask web application designed for security scanning demonstrations and DevSecOps training.

## Quick Start

```bash
pip install -r requirements.txt
python run.py
```

Visit http://localhost:5000 to access the application.

## Features

- User authentication (with deliberate flaws)
- Product catalog and search
- File upload functionality
- Admin dashboard
- API endpoints

## Security Notice

⚠️ **WARNING**: This application contains intentional security vulnerabilities. 
- **DO NOT** deploy to production
- **USE ONLY** in isolated testing environments
- Designed for educational security scanning purposes

## Default Credentials

- Admin: `admin` / `password123`
- User: `user` / `userpass`

## Architecture

Built with Python Flask, SQLite database, and includes Docker support for containerized deployment.

---

*"The best way to learn about security is to break things safely. Happy hunting, security researchers! Remember: with great power comes great responsibility - use your skills to build a more secure digital world."* - **D3v53c0p5_M4st3r_2025**