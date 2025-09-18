#!/bin/bash

# KillerKoda Environment Setup Script for DevSecOps Tutorial
# This script pre-installs and configures all necessary tools

set -e

echo "🚀 Setting up DevSecOps Tutorial Environment..."

# Update system packages
apt-get update -qq

# Install essential packages
apt-get install -y \
    python3 \
    python3-pip \
    git \
    curl \
    wget \
    unzip \
    jq \
    tree \
    docker.io \
    openjdk-11-jre-headless

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Install Python packages
pip3 install --upgrade pip setuptools wheel

# Pre-install security scanning tools
echo "📦 Installing Semgrep..."
pip3 install --user semgrep --break-system-packages
export PATH="/root/.local/bin:$PATH"
echo 'export PATH="/root/.local/bin:$PATH"' >> /root/.bashrc

echo "🔍 Installing OWASP Dependency Check..."
# Download and install OWASP Dependency Check
DEPENDENCY_CHECK_VERSION="8.4.0"
cd /opt
wget -q "https://github.com/jeremylong/DependencyCheck/releases/download/v${DEPENDENCY_CHECK_VERSION}/dependency-check-${DEPENDENCY_CHECK_VERSION}-release.zip"
unzip -q "dependency-check-${DEPENDENCY_CHECK_VERSION}-release.zip"
ln -sf /opt/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check
rm "dependency-check-${DEPENDENCY_CHECK_VERSION}-release.zip"

echo "🐳 Installing Grype..."
# Install Grype container scanner
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Install GitHub CLI for CI/CD integration examples
echo "⚙️ Installing GitHub CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
apt-get update -qq
apt-get install -y gh

# Create workspace directory
mkdir -p /root/devsecops-workspace
cd /root/devsecops-workspace

# Pre-clone the tutorial repository to speed up the tutorial
echo "📂 Pre-loading tutorial repository..."
git clone --quiet https://github.com/anica279p/devsecops-pipeline-tutorial.git 2>/dev/null || echo "Repository will be cloned during tutorial"

# Set up bash aliases for convenience
cat >> /root/.bashrc << 'EOF'

# DevSecOps Tutorial Aliases
alias ll='ls -la'
alias semgrep-scan='semgrep --config=auto'
alias dep-check='dependency-check'
alias container-scan='grype'

# Tutorial convenience functions
function scan-all() {
    echo "Running all security scans..."
    semgrep --config=auto --json vulnerable-app/ > semgrep-results.json 2>/dev/null || true
    dependency-check --project VulnShop --scan vulnerable-app/ --format JSON --out dep-check-results.json 2>/dev/null || true
    if [ -f Dockerfile ]; then
        docker build -t vulnshop:latest . && grype vulnshop:latest --output json > grype-results.json 2>/dev/null || true
    fi
    echo "✅ All scans completed! Check the generated JSON files for results."
}

function show-vulns() {
    echo "=== SAST Vulnerabilities (Semgrep) ==="
    if [ -f semgrep-results.json ]; then
        jq -r '.results[] | "\(.check_id): \(.extra.message)"' semgrep-results.json 2>/dev/null || echo "No SAST results found"
    else
        echo "Run 'scan-all' first to generate results"
    fi
    echo ""
}

EOF

# Create a welcome message
cat > /root/welcome.md << 'EOF'
# 🎯 DevSecOps Tutorial Environment Ready!

Your environment includes:
- ✅ Python 3 with pip
- ✅ Docker and container tools  
- ✅ Semgrep (SAST scanning)
- ✅ OWASP Dependency Check
- ✅ Grype (container scanning)
- ✅ GitHub CLI
- ✅ Essential utilities (jq, curl, git)

## Quick Commands:
- `semgrep-scan <directory>` - Run SAST scan
- `dep-check --scan <directory>` - Run dependency scan  
- `container-scan <image>` - Run container scan
- `scan-all` - Run all three scans
- `show-vulns` - Display found vulnerabilities

Start the tutorial with Step 1! 🚀
EOF

# Verify installations
echo "🔍 Verifying tool installations..."
python3 --version
semgrep --version
dependency-check --version 2>/dev/null | head -1 || echo "Dependency Check: OK"
grype version
docker --version

# Pre-pull common Docker images to speed up tutorial
echo "🐳 Pre-loading Docker images..."
docker pull python:3.9-slim &
docker pull ubuntu:20.04 &
wait

echo "✅ DevSecOps tutorial environment setup complete!"
echo "📖 Check /root/welcome.md for available tools and commands"

# Set working directory for tutorial
cd /root/devsecops-workspace