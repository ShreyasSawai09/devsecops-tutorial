#!/bin/bash

# Step 5 Verification: Grype image scan completed

echo "Verifying Step 5: Container scanning with Grype..."

# Check docker and grype availability
if ! command -v docker &> /dev/null; then
  echo "❌ Docker not installed."
  exit 1
fi
if ! command -v grype &> /dev/null; then
  echo "❌ Grype not installed."
  exit 1
fi

# Ensure a recent build exists
if ! docker image ls | awk '{print $1":"$2}' | grep -q "vulnshop:workshop"; then
  echo "❌ Image vulnshop:workshop not found. Build it as instructed."
  exit 1
fi

# Verify results file
if [ ! -f "grype-results.json" ]; then
  echo "❌ grype-results.json not found. Run the scan command."
  exit 1
fi

TOTAL=$(jq '.matches | length' grype-results.json 2>/dev/null || echo "0")
if [ "$TOTAL" -eq 0 ]; then
  echo "⚠️  No vulnerabilities detected; expected some in this tutorial image."
fi

HIGH=$(jq '[.matches[] | select(.vulnerability.severity=="High" or .vulnerability.severity=="Critical")] | length' grype-results.json 2>/dev/null || echo "0")

echo "✅ Grype scan results present; total findings: $TOTAL (High/Critical: $HIGH)"
echo "✅ Step 5 Complete: Container scanning performed"
echo "Proceed to CI/CD integration to enforce thresholds."


