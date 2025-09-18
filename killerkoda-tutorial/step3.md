# Step 3: Static Application Security Testing (SAST) with Semgrep

## Understanding Static Application Security Testing

**Static Application Security Testing (SAST)** analyzes source code without executing the application to identify security vulnerabilities. Unlike dynamic testing that requires a running application, SAST provides:

- **Early detection** of vulnerabilities during development
- **Complete code coverage** including rarely executed paths  
- **Precise vulnerability location** with exact line numbers
- **Fast feedback** integrated into developer workflows
- **Scalable analysis** across large codebases

## Introduction to Semgrep

Semgrep is a modern SAST tool that uses pattern-based static analysis to find security vulnerabilities, bugs, and code quality issues. It stands out because it:

- **Understands code structure** rather than just text patterns
- **Supports multiple languages** including Python, JavaScript, Java, Go, C++
- **Provides low false positives** through intelligent pattern matching
- **Allows custom rules** for organization-specific security requirements
- **Integrates seamlessly** with CI/CD pipelines

### Semgrep Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        SEMGREP ANALYSIS ENGINE                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐ │
│  │   SOURCE CODE   │    │   SEMGREP       │    │   VULNERABILITY │ │
│  │     INPUT       │───▶│   RULES         │───▶│    REPORTS      │ │
│  │                 │    │                 │    │                 │ │
│  │ • Python Files  │    │ • Pattern Match │    │ • JSON Output   │ │
│  │ • Config Files  │    │ • AST Analysis  │    │ • SARIF Format  │ │
│  │ • Templates     │    │ • Data Flow     │    │ • CLI Reports   │ │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘ │
│                                 │                                   │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    RULE SOURCES                             │   │
│  │                                                             │   │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐ │   │
│  │ │ COMMUNITY   │ │   CUSTOM    │ │      ORGANIZATION       │ │   │
│  │ │   RULES     │ │   RULES     │ │        POLICIES         │ │   │
│  │ │             │ │             │ │                         │ │   │
│  │ │ • p/security│ │ • .semgrep  │ │ • Company Standards     │ │   │
│  │ │ • p/owasp   │ │   .yml      │ │ • Regulatory Compliance │ │   │
│  │ │ • p/secrets │ │ • Custom    │ │ • Industry Best Practice│ │   │
│  │ └─────────────┘ └─────────────┘ └─────────────────────────┘ │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

## Semgrep Rule Structure and Customization

Before running scans, let's understand how Semgrep rules work and examine our custom configuration:

Return to the project root to access configuration files
```bash
cd ../
```{{exec}}

Examine the custom Semgrep rules we've created
```bash
cat .semgrep.yml
```{{exec}}

### Rule Anatomy Breakdown

Let's examine one rule in detail to understand the pattern matching:

Extract and explain a specific rule
Example: SQL Injection Detection Rule
```bash
echo "───────────────────────────────────────"
cat << 'EOF'
- id: sql-injection-string-concat
  patterns:
    - pattern-either:
        - pattern: $CURSOR.execute(... + $VAR + ...)
        - pattern: $CURSOR.execute($STR % $VAR)
  message: |
    SQL injection vulnerability: String concatenation used in SQL query.
  languages: [python]
  severity: ERROR

BREAKDOWN:
• id: Unique identifier for this rule
• patterns: What code patterns to match
• pattern-either: Match any of these patterns
• $CURSOR, $VAR: Metavariables that match any expression
• message: Description shown to developers
• severity: ERROR/WARNING/INFO classification
EOF
```{{exec}}

## Running Comprehensive SAST Scans

Now let's perform systematic security analysis using different Semgrep configurations:

### Scan 1: Custom Rules Analysis
Run our custom security rules against the vulnerable application
```bash
semgrep --config=.semgrep.yml vulnerable-app/ --json > semgrep-custom-results.json
```{{exec}}

Display formatted results from custom rules
```bash
jq -r '.results[] | "
VULNERABILITY: \(.check_id)
File: \(.path)
Line: \(.start.line)
Severity: \(.extra.severity)
Message: \(.extra.message)
────────────────────────────────────────
"' semgrep-custom-results.json
```{{exec}}

### Scan 2: Community Security Rules

Run community security rules for broader coverage
```bash
semgrep --config=p/security-audit --config=p/secrets vulnerable-app/ --json > semgrep-community-results.json
```{{exec}}

 Analyze community rule findings
```bash
echo "Total findings: $(jq '.results | length' semgrep-community-results.json)"
echo ""
echo "Findings by severity:"
echo "• Critical: $(jq '[.results[] | select(.extra.severity=="ERROR")] | length' semgrep-community-results.json)"
echo "• Warning: $(jq '[.results[] | select(.extra.severity=="WARNING")] | length' semgrep-community-results.json)"
echo "• Info: $(jq '[.results[] | select(.extra.severity=="INFO")] | length' semgrep-community-results.json)"
```{{exec}}


## Comprehensive Vulnerability Analysis

Let's create a unified analysis of all detected vulnerabilities:
Combine all scan results for comprehensive analysis
```bash
jq -s 'map(.results // []) | add | {results: .}' \
   semgrep-custom-results.json semgrep-community-results.json > semgrep-combined-results.json

TOTAL_FINDINGS=$(jq '.results | length' semgrep-combined-results.json)
CRITICAL_COUNT=$(jq '[.results[] | select(.extra.severity=="ERROR")] | length' semgrep-combined-results.json)
WARNING_COUNT=$(jq '[.results[] | select(.extra.severity=="WARNING")] | length' semgrep-combined-results.json)

echo "📊 SCAN SUMMARY"
echo "═══════════════════════════════════════════════════"
echo "Total Unique Vulnerabilities: $TOTAL_FINDINGS"
echo "Critical (ERROR): $CRITICAL_COUNT"
echo "Warning: $WARNING_COUNT"
echo ""
```{{exec}}

### Critical Vulnerability Deep Dive
Analyze critical vulnerabilities in detail

```bash
jq -r '.results[] | select(.extra.severity=="ERROR") | "
🔴 CRITICAL: \(.check_id)
Location: \(.path):\(.start.line)
Issue: \(.extra.message)
Impact: " + (
  if (.check_id | contains("sql-injection")) then "Data breach, authentication bypass"
  elif (.check_id | contains("command-injection")) then "Remote code execution"
  elif (.check_id | contains("pickle")) then "Remote code execution via deserialization"
  else "High security risk"
  end
) + "

Remediation Priority: IMMEDIATE
────────────────────────────────────────────────────────
"' semgrep-combined-results.json
```{{exec}}

## SAST Integration and Automation

### Command Line Integration Options
Demonstrate different Semgrep output formats for CI/CD integration
1. JSON Format (for automation):
```bash
echo "   semgrep --config=auto --json vulnerable-app/"
```{{exec}}

2. SARIF Format (for GitHub Security tab):
```bash
echo "   semgrep --config=auto --sarif vulnerable-app/"
```{{exec}}

3. GitLab SAST Format:
```bash
echo "   semgrep --config=auto --gitlab-sast vulnerable-app/"
```{{exec}}

4. JUnit XML (for test integration):
```bash
echo "   semgrep --config=auto --junit-xml vulnerable-app/"
```{{exec}}

### Security Gate Implementation

Create a security gate script for CI/CD integration
```bash
cat > sast-security-gate.sh << 'EOF'
#!/bin/bash
echo "=== SAST SECURITY GATE EVALUATION ==="

# Run Semgrep and capture results
semgrep --config=auto --json vulnerable-app/ > gate-scan-results.json

# Extract metrics
TOTAL_ISSUES=$(jq '.results | length' gate-scan-results.json)
CRITICAL_ISSUES=$(jq '[.results[] | select(.extra.severity=="ERROR")] | length' gate-scan-results.json)
HIGH_ISSUES=$(jq '[.results[] | select(.extra.severity=="WARNING")] | length' gate-scan-results.json)

echo "Scan Results:"
echo "• Total Issues: $TOTAL_ISSUES"
echo "• Critical: $CRITICAL_ISSUES"  
echo "• High: $HIGH_ISSUES"
echo ""

# Security gate logic
if [ "$CRITICAL_ISSUES" -gt 0 ]; then
    echo "❌ SECURITY GATE FAILED"
    echo "   Critical vulnerabilities detected: $CRITICAL_ISSUES"
    echo "   Build should be blocked in CI/CD pipeline"
    echo ""
    echo "Critical Issues:"
    jq -r '.results[] | select(.extra.severity=="ERROR") | "   • \(.check_id) (\(.path):\(.start.line))"' gate-scan-results.json
    exit 1
elif [ "$HIGH_ISSUES" -gt 5 ]; then
    echo "⚠️  SECURITY GATE WARNING"
    echo "   High severity issues exceed threshold: $HIGH_ISSUES > 5"
    echo "   Consider reviewing before deployment"
    exit 1
else
    echo "✅ SECURITY GATE PASSED"
    echo "   Security findings within acceptable limits"
    exit 0
fi
EOF

chmod +x sast-security-gate.sh
```{{exec}}

Test the security gate
```bash
./sast-security-gate.sh
```{{exec}}

## Advanced Semgrep Techniques

### Custom Rule Development

Create an additional custom rule for organization-specific patterns

```bash
cat > advanced-custom-rules.yml << 'EOF'
rules:
  - id: dangerous-admin-operations
    patterns:
      - pattern-either:
          - pattern: |
              if session['role'] == 'admin':
                ...
                $DANGEROUS_CALL
          - pattern: |
              @app.route($PATH, methods=[..., "POST", ...])
              def $FUNC(...):
                ...
                if $ROLE == 'admin':
                  ...
                  $DANGEROUS_CALL
    metavariable-pattern:
      metavariable: $DANGEROUS_CALL
      patterns:
        - pattern-either:
            - pattern: subprocess.run(...)
            - pattern: pickle.loads(...)
            - pattern: eval(...)
            - pattern: exec(...)
    message: |
      Dangerous operation in admin context. Admin privilege escalation
      could allow system compromise.
    languages: [python]
    severity: ERROR

  - id: insecure-session-config
    pattern: |
      app.secret_key = $SECRET
    metavariable-regex:
      metavariable: $SECRET
      regex: '^"[^"]{1,16}"$'
    message: |
      Weak secret key detected. Use cryptographically strong keys
      of at least 32 characters.
    languages: [python]
    severity: WARNING
EOF
```{{exec}}

Test the advanced custom rules
```bash
semgrep --config=advanced-custom-rules.yml vulnerable-app/ --json | jq -r '.results[] | "
Advanced Rule: \(.check_id)
Finding: \(.extra.message)
Location: \(.path):\(.start.line)
────────────────────────────────────────
"'
```{{exec}}

### Performance and Optimization
Demonstrate Semgrep performance optimization

1. Excluding files for faster scans:
```bash
echo "   semgrep --config=auto --exclude='*.log' --exclude='test_*' vulnerable-app/"
```{{exec}}

2. Scanning specific file types only:
```bash
echo "   semgrep --config=auto --include='*.py' vulnerable-app/"
```{{exec}}

3. Using specific rule sets for targeted scanning:
```bash
echo "   semgrep --config=p/security-audit vulnerable-app/"
```{{exec}}


# Measure scan performance
4. Performance measurement:
```bash
time semgrep --config=.semgrep.yml vulnerable-app/ --quiet >/dev/null
```{{exec}}

## SAST Results Interpretation and Prioritization

### Vulnerability Risk Assessment
Create a comprehensive vulnerability assessment
```bash
cat > vulnerability-assessment.sh << 'EOF'
#!/bin/bash
echo "=== SAST VULNERABILITY RISK ASSESSMENT ==="
echo ""

# Load scan results
RESULTS_FILE="semgrep-combined-results.json"

echo "📋 VULNERABILITY BREAKDOWN BY CATEGORY:"
echo "════════════════════════════════════════════════════"

# SQL Injection Analysis
SQL_INJ_COUNT=$(jq '[.results[] | select(.check_id | contains("sql"))] | length' $RESULTS_FILE)
echo "🔴 SQL Injection Vulnerabilities: $SQL_INJ_COUNT"
echo "   Risk Level: CRITICAL (CVSS 9.0+)"
echo "   Impact: Data breach, authentication bypass"
echo "   Remediation: Use parameterized queries"
echo ""

# Command Injection Analysis  
CMD_INJ_COUNT=$(jq '[.results[] | select(.check_id | contains("command"))] | length' $RESULTS_FILE)
echo "🔴 Command Injection Vulnerabilities: $CMD_INJ_COUNT"
echo "   Risk Level: CRITICAL (CVSS 9.0+)"
echo "   Impact: Remote code execution"
echo "   Remediation: Input validation, avoid shell=True"
echo ""

# Hardcoded Secrets Analysis
SECRET_COUNT=$(jq '[.results[] | select(.check_id | contains("secret"))] | length' $RESULTS_FILE)
echo "🟡 Hardcoded Secrets: $SECRET_COUNT"
echo "   Risk Level: HIGH (CVSS 7.0+)"
echo "   Impact: Authentication bypass, session hijacking"
echo "   Remediation: Use environment variables"
echo ""

# Deserialization Analysis
PICKLE_COUNT=$(jq '[.results[] | select(.check_id | contains("pickle"))] | length' $RESULTS_FILE)
echo "🔴 Insecure Deserialization: $PICKLE_COUNT"
echo "   Risk Level: CRITICAL (CVSS 9.0+)"
echo "   Impact: Remote code execution"
echo "   Remediation: Use JSON or signed serialization"
echo ""

echo "📊 REMEDIATION PRIORITY MATRIX:"
echo "════════════════════════════════════════════════════"
echo "Priority 1 (Fix immediately): SQL Injection, Command Injection, Deserialization"
echo "Priority 2 (Fix this week): Hardcoded secrets, Authentication issues"
echo "Priority 3 (Fix this sprint): Configuration issues, Debug mode"
EOF

chmod +x vulnerability-assessment.sh
./vulnerability-assessment.sh
```{{exec}}

## SAST Implementation Summary

Let's create a final summary of our SAST implementation:
TOOLS CONFIGURED:
  • Semgrep installed and verified
  • Custom rules created for organization needs
  • Community rules integrated
  • Multiple output formats available

SCANNING RESULTS:
  • Total vulnerabilities detected: $(jq '.results | length' semgrep-combined-results.json)
  • Critical issues requiring immediate attention: $(jq '[.results[] | select(.extra.severity=="ERROR")] | length' semgrep-combined-results.json)
  • Security gate implementation: Complete

CI/CD INTEGRATION READY:
  • JSON output for automation
  • SARIF format for GitHub integration
  • Security gate script created
  • Performance optimized


✅ SAST IMPLEMENTATION: COMPLETE

Next: Dependency vulnerability scanning with OWASP Dependency Check


## Key Achievements

Through this comprehensive SAST implementation with Semgrep, you have:

1. **Mastered SAST fundamentals** and understood how static analysis detects vulnerabilities
2. **Configured custom security rules** tailored to your application's specific security requirements
3. **Integrated community rules** for broader vulnerability coverage
4. **Implemented security gates** that can block deployments with critical vulnerabilities
5. **Created automated workflows** ready for CI/CD pipeline integration
6. **Developed risk assessment capabilities** for vulnerability prioritization

Your SAST implementation provides the first pillar of comprehensive DevSecOps security scanning. In the next steps, you'll add dependency vulnerability scanning and container security analysis to create complete security coverage.