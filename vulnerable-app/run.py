#!/usr/bin/env python3
"""
VulnShop - Intentionally Vulnerable E-commerce Application
Run this script to start the application locally for development and testing.
"""

import os
import sys
import subprocess
import sqlite3
from app import init_db

def check_dependencies():
    """Check if all required packages are installed."""
    try:
        import flask
        import sqlite3
        import requests
        print("✓ All dependencies are available")
        return True
    except ImportError as e:
        print(f"✗ Missing dependency: {e}")
        print("Please run: pip install -r requirements.txt")
        return False

def setup_database():
    """Initialize the database with sample data."""
    print("Setting up database...")
    init_db()
    print("✓ Database initialized with sample data")

def create_uploads_dir():
    """Create uploads directory if it doesn't exist."""
    if not os.path.exists('uploads'):
        os.makedirs('uploads')
        print("✓ Created uploads directory")
    else:
        print("✓ Uploads directory exists")

def display_banner():
    """Display application banner with vulnerability warnings."""
    banner = """
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║  ██╗   ██╗██╗   ██╗██╗     ███╗   ██╗███████╗██╗  ██╗ ██████╗ ██████╗       ║
║  ██║   ██║██║   ██║██║     ████╗  ██║██╔════╝██║  ██║██╔═══██╗██╔══██╗      ║
║  ██║   ██║██║   ██║██║     ██╔██╗ ██║███████╗███████║██║   ██║██████╔╝      ║
║  ╚██╗ ██╔╝██║   ██║██║     ██║╚██╗██║╚════██║██╔══██║██║   ██║██╔═══╝       ║
║   ╚████╔╝ ╚██████╔╝███████╗██║ ╚████║███████║██║  ██║╚██████╔╝██║           ║
║    ╚═══╝   ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝           ║
║                                                                              ║
║                    INTENTIONALLY VULNERABLE WEB APPLICATION                  ║
║                          FOR DEVSECOPS TRAINING ONLY                        ║
║                                                                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  ⚠️  WARNING: This application contains intentional security vulnerabilities ║
║  🚫  DO NOT deploy this application in a production environment             ║
║  🔒  Use only for educational and testing purposes                          ║
║  🛡️  Contains: SQL Injection, XSS, Command Injection, File Upload vulns    ║
╚══════════════════════════════════════════════════════════════════════════════╝
"""
    print(banner)

def display_test_accounts():
    """Display available test accounts."""
    print("\n📋 Test Accounts:")
    print("┌─────────────────┬──────────────┬─────────────────────────────────────┐")
    print("│ Username        │ Password     │ Description                         │")
    print("├─────────────────┼──────────────┼─────────────────────────────────────┤")
    print("│ admin           │ admin123     │ Administrator account               │")
    print("│ user            │ password     │ Regular user account                │")
    print("└─────────────────┴──────────────┴─────────────────────────────────────┘")

def display_vulnerabilities():
    """Display list of vulnerabilities included."""
    print("\n🐛 Included Vulnerabilities:")
    vulnerabilities = [
        "SQL Injection (Login & Search)",
        "Command Injection (Admin panel)",
        "Unrestricted File Upload",
        "Insecure Direct Object Reference (IDOR)",
        "Insecure Deserialization", 
        "Open Redirect",
        "Hardcoded Secrets",
        "Vulnerable Dependencies",
        "Missing Authentication",
        "Debug Mode Enabled"
    ]
    
    for i, vuln in enumerate(vulnerabilities, 1):
        print(f"  {i:2}. {vuln}")

def display_endpoints():
    """Display available endpoints for testing."""
    print("\n🌐 Key Endpoints:")
    endpoints = [
        ("http://localhost:5000/", "Home page with vulnerability overview"),
        ("http://localhost:5000/login", "Vulnerable login form (SQL injection)"),
        ("http://localhost:5000/search", "Product search (SQL injection)"),
        ("http://localhost:5000/profile", "User profile (IDOR vulnerability)"),
        ("http://localhost:5000/upload", "File upload (unrestricted upload)"),
        ("http://localhost:5000/api/user/1", "API endpoint (no authentication)"),
        ("http://localhost:5000/execute", "Admin command execution (POST)")
    ]
    
    for endpoint, description in endpoints:
        print(f"  • {endpoint}")
        print(f"    {description}")

def main():
    """Main application runner."""
    display_banner()
    
    print("Starting VulnShop application setup...\n")
    
    # Check dependencies
    if not check_dependencies():
        sys.exit(1)
    
    # Setup database
    setup_database()
    
    # Create uploads directory
    create_uploads_dir()
    
    print("\n" + "="*80)
    display_test_accounts()
    display_vulnerabilities()
    display_endpoints()
    print("\n" + "="*80)
    
    print("\n🚀 Starting Flask application...")
    print("📍 Application will be available at: http://localhost:5000")
    print("🔧 Debug mode: ENABLED (intentionally vulnerable)")
    print("⚠️  Press Ctrl+C to stop the application\n")
    
    try:
        # Import and run the Flask app
        from app import app
        app.run(debug=True, host='0.0.0.0', port=5000)
    except KeyboardInterrupt:
        print("\n\n👋 Application stopped by user")
    except Exception as e:
        print(f"\n❌ Error starting application: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()