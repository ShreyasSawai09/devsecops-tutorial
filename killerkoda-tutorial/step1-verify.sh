#!/bin/bash

# Step 1 Verification: Basic environment check

echo "Verifying Step 1: DevSecOps Fundamentals & Environment Setup..."

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "Python 3 not found"
    exit 1
fi

# Check if Git is available  
if ! command -v git &> /dev/null; then
    echo "Git not found"
    exit 1
fi

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "Docker not found"
    exit 1
fi

echo "Step 1 Complete: Environment verified and ready"
echo "Python 3, Git, and Docker are available"
echo "Ready to proceed to exploring the vulnerable application!"