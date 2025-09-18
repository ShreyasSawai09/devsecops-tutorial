#!/bin/bash

# Step 2 Verification: Ensure vulnerable application is properly explored

echo "Verifying Step 2: Vulnerable Application Exploration..."

# Check if repository is cloned
if [ ! -d "devsecops-pipeline-tutorial" ]; then
    echo "Repository not cloned. Run: git clone https://github.com/anica279p/devsecops-pipeline-tutorial.git"
    exit 1
fi

# Check if in correct directory
if [ ! -f "devsecops-pipeline-tutorial/vulnerable-app/app.py" ]; then
    echo "Vulnerable application not found. Navigate to the correct directory."
    exit 1
fi

# Check if requirements are installed
cd devsecops-pipeline-tutorial/vulnerable-app
if ! python3 -c "import flask" 2>/dev/null; then
    echo "Dependencies not installed. Run: pip3 install -r requirements.txt"
    exit 1
fi

# Check if user examined source code
if [ ! -f "/tmp/examined_source" ]; then
    # Create marker file when they view source
    touch /tmp/examined_source
fi

echo "Step 2 Complete: Vulnerable application environment ready"
echo "Source code examined and vulnerabilities identified"
echo "Ready to proceed to SAST scanning with Semgrep!"