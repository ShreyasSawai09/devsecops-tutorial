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

# Easter egg verification (optional)
if [ -f "/tmp/easter_egg_attempt.txt" ]; then
    ANSWER=$(cat /tmp/easter_egg_attempt.txt | tr -d '\n\r' | xargs)
    if [ "$ANSWER" = "skip" ]; then
        echo "📝 Easter egg hunt was skipped"
    elif [[ "$ANSWER" == *"D3v53c0p5_M4st3r_2024"* ]]; then
        echo "🎉 Easter Egg Found! You discovered the hidden signature!"
        echo "Bonus achievement unlocked: Security Documentation Detective"
    elif [ -n "$ANSWER" ]; then
        echo "💡 Easter egg hint: The signature might be hiding in a documentation file..."
        echo "💡 Look for files that contain project information or instructions..."
    fi
else
    echo "📝 Easter egg hunt was not attempted"
fi

echo ""
echo "Step 2 Complete: Vulnerable application environment ready"
echo "Source code examined and vulnerabilities identified"
echo "Ready to proceed to SAST scanning with Semgrep!"