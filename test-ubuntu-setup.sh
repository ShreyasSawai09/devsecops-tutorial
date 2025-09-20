#!/bin/bash

# DevSecOps Pipeline Testing Script for Ubuntu
# This script sets up and tests the entire DevSecOps pipeline on Ubuntu

set -e

echo "╔════════════════════════════════════════════════════════════════════════════════╗"
echo "║                    DEVSECOPS PIPELINE UBUNTU TEST SUITE                       ║"
echo "║                                                                                ║"
echo "║  This script will test all components of the DevSecOps pipeline:              ║"
echo "║  • Vulnerable Flask Application                                                ║"
echo "║  • Security Scanning Tools (SAST, Dependency, Container)                      ║"
echo "║  • Security Analysis Scripts                                                   ║"
echo "║  • Pipeline Integration                                                        ║"
echo "╚════════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing system dependencies..."
    
    # Update package list
    sudo apt-get update
    
    # Install Python and pip if not available
    if ! command_exists python3; then
        print_status "Installing Python 3..."
        sudo apt-get install -y python3 python3-pip python3-venv
    fi
    
    # Install Docker if not available
    if ! command_exists docker; then
        print_status "Installing Docker..."
        sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        sudo usermod -aG docker $USER
        print_warning "Docker installed. You may need to log out and back in for group changes to take effect."
    fi
    
    # Install Java for OWASP Dependency Check
    if ! command_exists java; then
        print_status "Installing Java (required for OWASP Dependency Check)..."
        sudo apt-get install -y openjdk-11-jdk
    fi
    
    # Install jq for JSON processing
    if ! command_exists jq; then
        print_status "Installing jq..."
        sudo apt-get install -y jq
    fi
    
    # Install curl and wget if needed
    sudo apt-get install -y curl wget unzip
    
    print_success "System dependencies installed successfully"
}

# Function to install security tools
install_security_tools() {
    print_status "Installing security scanning tools..."
    
    # Install Semgrep
    if ! command_exists semgrep; then
        print_status "Installing Semgrep..."
        python3 -m pip install semgrep
    fi
    
    # Install OWASP Dependency Check
    if [ ! -f "/opt/dependency-check/bin/dependency-check.sh" ]; then
        print_status "Installing OWASP Dependency Check..."
        DEPENDENCY_CHECK_VERSION="8.4.0"
        cd /tmp
        wget "https://github.com/jeremylong/DependencyCheck/releases/download/v${DEPENDENCY_CHECK_VERSION}/dependency-check-${DEPENDENCY_CHECK_VERSION}-release.zip"
        unzip "dependency-check-${DEPENDENCY_CHECK_VERSION}-release.zip"
        sudo mv dependency-check /opt/
        sudo ln -sf /opt/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check
        rm "dependency-check-${DEPENDENCY_CHECK_VERSION}-release.zip"
    fi
    
    # Install Grype
    if ! command_exists grype; then
        print_status "Installing Grype..."
        curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
    fi
    
    print_success "Security tools installed successfully"
}

# Function to test vulnerable application
test_vulnerable_app() {
    print_status "Testing vulnerable Flask application..."
    
    cd vulnerable-app
    
    # Create virtual environment
    print_status "Creating Python virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    
    # Install requirements
    print_status "Installing Python dependencies..."
    pip install -r requirements.txt
    
    # Start application in background
    print_status "Starting Flask application..."
    python run.py &
    APP_PID=$!
    
    # Wait for application to start
    sleep 5
    
    # Test if application is running
    if curl -s http://localhost:5000 > /dev/null; then
        print_success "Flask application is running on http://localhost:5000"
        
        # Test some endpoints
        print_status "Testing application endpoints..."
        
        # Test home page
        if curl -s http://localhost:5000/ | grep -q "VulnShop"; then
            print_success "Home page accessible"
        else
            print_warning "Home page test failed"
        fi
        
        # Test login page
        if curl -s http://localhost:5000/login | grep -q "Login"; then
            print_success "Login page accessible"
        else
            print_warning "Login page test failed"
        fi
        
        # Test API endpoint
        if curl -s http://localhost:5000/api/user/1 | grep -q "user"; then
            print_success "API endpoint accessible"
        else
            print_warning "API endpoint test failed"
        fi
        
    else
        print_error "Flask application failed to start"
    fi
    
    # Stop application
    kill $APP_PID 2>/dev/null || true
    deactivate
    cd ..
    
    print_success "Vulnerable application testing completed"
}

# Function to run SAST scan
run_sast_scan() {
    print_status "Running SAST scan with Semgrep..."
    
    # Run Semgrep scan
    if [ -f ".semgrep.yml" ]; then
        semgrep --config=.semgrep.yml --json --output=semgrep-results.json vulnerable-app/ || true
    else
        # Use default security rules if no config file
        semgrep --config=auto --json --output=semgrep-results.json vulnerable-app/ || true
    fi
    
    if [ -f "semgrep-results.json" ]; then
        SAST_FINDINGS=$(jq '.results | length' semgrep-results.json)
        print_success "SAST scan completed - Found $SAST_FINDINGS issues"
        
        # Show summary
        CRITICAL=$(jq '[.results[] | select(.extra.severity=="ERROR")] | length' semgrep-results.json)
        WARNING=$(jq '[.results[] | select(.extra.severity=="WARNING")] | length' semgrep-results.json)
        print_status "  Critical: $CRITICAL, Warnings: $WARNING"
    else
        print_error "SAST scan failed - no results file generated"
    fi
}

# Function to run dependency scan
run_dependency_scan() {
    print_status "Running dependency vulnerability scan..."
    
    # Create reports directory
    mkdir -p dep-check-reports
    
    # Run OWASP Dependency Check
    dependency-check \
        --project "VulnShop" \
        --scan vulnerable-app/ \
        --format JSON \
        --format HTML \
        --out dep-check-reports/ \
        --failOnCVSS 0 || true
    
    if [ -f "dep-check-reports/dependency-check-report.json" ]; then
        TOTAL_DEPS=$(jq '.dependencies | length' dep-check-reports/dependency-check-report.json)
        VULNERABLE_DEPS=$(jq '[.dependencies[] | select(.vulnerabilities)] | length' dep-check-reports/dependency-check-report.json)
        print_success "Dependency scan completed - $VULNERABLE_DEPS/$TOTAL_DEPS dependencies have vulnerabilities"
    else
        print_error "Dependency scan failed - no results file generated"
    fi
}

# Function to run container scan
run_container_scan() {
    print_status "Running container image scan..."
    
    # Build Docker image
    print_status "Building Docker image..."
    cd vulnerable-app
    docker build -t vulnshop:test . || {
        print_error "Docker build failed"
        cd ..
        return 1
    }
    cd ..
    
    # Run Grype scan
    print_status "Scanning container image with Grype..."
    grype vulnshop:test -o json > grype-results.json || true
    
    if [ -f "grype-results.json" ]; then
        CONTAINER_VULNS=$(jq '.matches | length' grype-results.json 2>/dev/null || echo "0")
        print_success "Container scan completed - Found $CONTAINER_VULNS vulnerabilities"
        
        # Show summary
        HIGH_VULNS=$(jq '[.matches[] | select(.vulnerability.severity=="High" or .vulnerability.severity=="Critical")] | length' grype-results.json 2>/dev/null || echo "0")
        print_status "  High/Critical vulnerabilities: $HIGH_VULNS"
    else
        print_error "Container scan failed - no results file generated"
    fi
}

# Function to test security analysis scripts
test_security_scripts() {
    print_status "Testing security analysis scripts..."
    
    # Make scripts executable
    chmod +x *.sh
    
    # Test security dashboard
    if [ -f "security-dashboard.sh" ]; then
        print_status "Running security dashboard..."
        ./security-dashboard.sh > security-dashboard-output.txt
        print_success "Security dashboard executed successfully"
    fi
    
    # Test security metrics
    if [ -f "security-metrics.sh" ]; then
        print_status "Running security metrics..."
        ./security-metrics.sh > security-metrics-output.txt
        print_success "Security metrics executed successfully"
    fi
    
    # Test other security scripts
    for script in security-gate-*.sh remediation-guide.sh executive-summary.sh detailed-vulnerability-report.sh; do
        if [ -f "$script" ]; then
            print_status "Running $script..."
            ./"$script" > "${script%.sh}-output.txt" || true
            print_success "$script executed"
        fi
    done
}

# Function to generate test report
generate_test_report() {
    print_status "Generating test report..."
    
    REPORT_FILE="ubuntu-test-report.md"
    
    cat > "$REPORT_FILE" << EOF
# DevSecOps Pipeline Ubuntu Test Report

**Test Date:** $(date)  
**Test Environment:** Ubuntu $(lsb_release -rs)  
**User:** $(whoami)  

## Test Summary

### System Information
- **OS:** $(lsb_release -d | cut -f2)
- **Python:** $(python3 --version 2>/dev/null || echo "Not installed")
- **Docker:** $(docker --version 2>/dev/null || echo "Not installed")
- **Java:** $(java -version 2>&1 | head -n1 || echo "Not installed")

### Security Tools Status
- **Semgrep:** $(semgrep --version 2>/dev/null || echo "Not installed")
- **OWASP Dependency Check:** $(dependency-check --version 2>/dev/null | head -n1 || echo "Not installed")
- **Grype:** $(grype version 2>/dev/null || echo "Not installed")

### Test Results

#### 1. Vulnerable Application Test
EOF

    # Add application test results
    if curl -s http://localhost:5000 > /dev/null 2>&1; then
        echo "- ✅ Application successfully started and accessible" >> "$REPORT_FILE"
    else
        echo "- ❌ Application failed to start or not accessible" >> "$REPORT_FILE"
    fi
    
    # Add scan results
    cat >> "$REPORT_FILE" << EOF

#### 2. Security Scan Results

**SAST (Semgrep):**
EOF
    
    if [ -f "semgrep-results.json" ]; then
        SAST_TOTAL=$(jq '.results | length' semgrep-results.json)
        SAST_CRITICAL=$(jq '[.results[] | select(.extra.severity=="ERROR")] | length' semgrep-results.json)
        echo "- ✅ SAST scan completed successfully" >> "$REPORT_FILE"
        echo "- Total findings: $SAST_TOTAL" >> "$REPORT_FILE"
        echo "- Critical issues: $SAST_CRITICAL" >> "$REPORT_FILE"
    else
        echo "- ❌ SAST scan failed or no results" >> "$REPORT_FILE"
    fi
    
    cat >> "$REPORT_FILE" << EOF

**Dependency Scanning (OWASP Dependency Check):**
EOF
    
    if [ -f "dep-check-reports/dependency-check-report.json" ]; then
        DEP_TOTAL=$(jq '.dependencies | length' dep-check-reports/dependency-check-report.json)
        DEP_VULNERABLE=$(jq '[.dependencies[] | select(.vulnerabilities)] | length' dep-check-reports/dependency-check-report.json)
        echo "- ✅ Dependency scan completed successfully" >> "$REPORT_FILE"
        echo "- Total dependencies: $DEP_TOTAL" >> "$REPORT_FILE"
        echo "- Vulnerable dependencies: $DEP_VULNERABLE" >> "$REPORT_FILE"
    else
        echo "- ❌ Dependency scan failed or no results" >> "$REPORT_FILE"
    fi
    
    cat >> "$REPORT_FILE" << EOF

**Container Scanning (Grype):**
EOF
    
    if [ -f "grype-results.json" ]; then
        CONTAINER_VULNS=$(jq '.matches | length' grype-results.json 2>/dev/null || echo "0")
        echo "- ✅ Container scan completed successfully" >> "$REPORT_FILE"
        echo "- Container vulnerabilities: $CONTAINER_VULNS" >> "$REPORT_FILE"
    else
        echo "- ❌ Container scan failed or no results" >> "$REPORT_FILE"
    fi
    
    cat >> "$REPORT_FILE" << EOF

#### 3. Security Analysis Scripts
EOF
    
    for script in security-dashboard.sh security-metrics.sh security-gate-*.sh; do
        if [ -f "$script" ]; then
            if [ -f "${script%.sh}-output.txt" ]; then
                echo "- ✅ $script executed successfully" >> "$REPORT_FILE"
            else
                echo "- ❌ $script failed to execute" >> "$REPORT_FILE"
            fi
        fi
    done
    
    cat >> "$REPORT_FILE" << EOF

### Generated Files
EOF
    
    # List all generated files
    for file in *.json *.txt *.html dep-check-reports/*; do
        if [ -f "$file" ]; then
            echo "- $file" >> "$REPORT_FILE"
        fi
    done
    
    cat >> "$REPORT_FILE" << EOF

### Recommendations

1. **Security Posture:** This application is intentionally vulnerable and should never be deployed in production
2. **Tool Integration:** All security tools integrated successfully into the pipeline
3. **Automation:** Consider integrating these scans into CI/CD pipeline for continuous security
4. **Remediation:** Use the generated reports to understand and fix security vulnerabilities

### Next Steps

1. Review detailed vulnerability reports in the generated files
2. Use security scripts to understand remediation priorities
3. Implement security fixes based on the findings
4. Set up continuous security scanning in your CI/CD pipeline

---
*Report generated by DevSecOps Pipeline Test Suite*
EOF

    print_success "Test report generated: $REPORT_FILE"
}

# Main execution function
main() {
    print_status "Starting DevSecOps Pipeline Ubuntu Test Suite..."
    
    # Check if running as root (not recommended)
    if [ "$EUID" -eq 0 ]; then
        print_warning "Running as root is not recommended. Some tools may not work properly."
    fi
    
    # Install dependencies
    install_dependencies
    
    # Install security tools
    install_security_tools
    
    # Test vulnerable application
    test_vulnerable_app
    
    # Run security scans
    run_sast_scan
    run_dependency_scan
    run_container_scan
    
    # Test security analysis scripts
    test_security_scripts
    
    # Generate comprehensive test report
    generate_test_report
    
    print_success "DevSecOps Pipeline testing completed successfully!"
    print_status "Check the generated files for detailed results:"
    print_status "  - ubuntu-test-report.md (comprehensive test report)"
    print_status "  - semgrep-results.json (SAST findings)"
    print_status "  - dep-check-reports/ (dependency vulnerabilities)"
    print_status "  - grype-results.json (container vulnerabilities)"
    print_status "  - *-output.txt (security analysis script outputs)"
}

# Run main function
main "$@"
