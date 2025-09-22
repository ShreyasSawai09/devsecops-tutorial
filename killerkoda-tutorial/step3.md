# Step 3: Static Application Security Testing (SAST) with Semgrep

## What is SAST?

**Static Application Security Testing (SAST)** analyzes source code without executing it to find security vulnerabilities. Unlike Dynamic Application Security Testing (DAST) which tests running applications, SAST can find vulnerabilities early in the development process.

### SAST Benefits:
- **Early Detection** - Find vulnerabilities during development
- **Complete Coverage** - Analyze all code paths, including rarely executed ones
- **Fast Feedback** - Results available in minutes, not hours
- **Precise Location** - Shows exact line numbers of vulnerable code

## Introducing Semgrep

Semgrep is a powerful SAST tool that uses pattern-based static analysis. It's particularly effective because it:
- **Understands Code Structure** - Not just text matching
- **Low False Positives** - Smart pattern matching reduces noise
- **Customizable Rules** - Write rules for your specific security needs
- **Multi-Language Support** - Python, JavaScript, Java, Go, and more

## Installing and Configuring Semgrep

Semgrep is already pre-installed in your environment. Let's verify:
```bash
semgrep --version
```{{exec}}

## Understanding Semgrep Rules

Semgrep rules are written in YAML and use pattern matching. Let's examine the custom rules we've created for our vulnerable application:

```bash
cd /root/devsecops-workspace/devsecops-pipeline-tutorial
cat .semgrep.yml
```{{exec}}

### Rule Breakdown

Each rule contains:
- **id**: Unique identifier
- **patterns**: What code patterns to match
- **message**: Description of the vulnerability
- **languages**: Which programming languages this rule applies to
- **severity**: ERROR, WARNING, or INFO

Let's look at one rule in detail:
```yaml
- id: sql-injection-string-concat
  patterns:
    - pattern-either:
        - pattern: $CURSOR.execute(... + $VAR + ...)
        - pattern: $CURSOR.execute($STR % $VAR)
  message: SQL injection vulnerability: String concatenation used in SQL query construction.
  languages: [python]
  severity: ERROR
```

This rule detects SQL injection by finding database cursor execute calls that use string concatenation.

## Running Your First SAST Scan

Let's run Semgrep on our vulnerable application:

```bash
semgrep --config=.semgrep.yml vulnerable-app/
```{{exec}}

You should see several vulnerabilities detected! Let's also run with community rules:

```bash
semgrep --config=auto vulnerable-app/
```{{exec}}

## Analyzing SAST Results

Let's get more detailed output in JSON format for easier analysis:

```bash
semgrep --config=.semgrep.yml --json vulnerable-app/ > semgrep-results.json
```{{exec}}

View the results:
```bash
cat semgrep-results.json | jq '.'
```{{exec}}

Count the vulnerabilities by severity:
```bash
echo "=== SEMGREP SCAN RESULTS ==="
echo "Total findings: $(jq '.results | length' semgrep-results.json)"
echo "Critical (ERROR): $(jq '[.results[] | select(.extra.severity=="ERROR")] | length' semgrep-results.json)"
echo "Warnings: $(jq '[.results[] | select(.extra.severity=="WARNING")] | length' semgrep-results.json)"
```{{exec}}

Let's examine each finding:
```bash
echo "=== DETAILED FINDINGS ==="
jq -r '.results[] | "File: \(.path)\nLine: \(.start.line)\nSeverity: \(.extra.severity)\nIssue: \(.check_id)\nMessage: \(.extra.message)\n---"' semgrep-results.json
```{{exec}}

## Understanding the Detected Vulnerabilities

### 1. SQL Injection Detection
Semgrep found SQL injection vulnerabilities where user input is directly concatenated into SQL queries. This is exactly the type of critical security flaw that can lead to data breaches.

### 2. Command Injection
The tool detected the dangerous `subprocess.run()` call with `shell=True` that allows arbitrary command execution.

### 3. Hardcoded Secrets
Found the hardcoded Flask secret key that should be stored in environment variables.

### 4. Insecure Deserialization
Detected the dangerous `pickle.loads()` call that can lead to remote code execution.

### 5. Debug Mode Configuration
Identified Flask debug mode being enabled, which should never happen in production.

## Creating Custom Security Rules

Let's create an additional custom rule to detect a specific pattern in our application. Create a new rule file:

```bash
cat > custom-rules.yml << 'EOF'
rules:
  - id: dangerous-admin-functions
    patterns:
      - pattern: |
          @app.route($PATH, methods=[..., "POST", ...])
          def $FUNC(...):
            ...
            if session['role'] != 'admin':
              ...
            ...
            $DANGEROUS_CALL
      - metavariable-pattern:
          metavariable: $DANGEROUS_CALL
          patterns:
            - pattern-either:
                - pattern: subprocess.run(...)
                - pattern: pickle.loads(...)
                - pattern: eval(...)
    message: |
      Dangerous function in admin-only endpoint. Admin privilege escalation
      could allow remote code execution.
    languages: [python]
    severity: ERROR
EOF
```{{exec}}

Run the custom rule:
```bash
semgrep --config=custom-rules.yml vulnerable-app/
```{{exec}}

## SAST Integration Best Practices

### 1. Rule Configuration Strategy
```bash
echo "=== SEMGREP CONFIGURATION STRATEGIES ==="
echo ""
echo "1. Use community rules for broad coverage:"
echo "   semgrep --config=auto"
echo ""
echo "2. Use specific rulesets:"
echo "   semgrep --config=p/security-audit"
echo "   semgrep --config=p/secrets"
echo ""
echo "3. Combine community + custom rules:"
echo "   semgrep --config=auto --config=.semgrep.yml"
```{{exec}}

### 2. Output Formats
Semgrep supports multiple output formats for different use cases:

```bash
# JSON for CI/CD automation
semgrep --config=auto --json vulnerable-app/ > results.json

# SARIF for GitHub security tab integration  
semgrep --config=auto --sarif vulnerable-app/ > results.sarif

# GitLab SAST format
semgrep --config=auto --gitlab-sast vulnerable-app/ > gl-sast-report.json
```{{exec}}

## Fixing a Critical Vulnerability

Let's demonstrate how to fix one of the SQL injection vulnerabilities. First, let's look at the vulnerable code:

```bash
grep -n -A 3 -B 3 "SELECT.*FROM users WHERE" vulnerable-app/app.py
```{{exec}}

The vulnerable line uses string formatting. Here's how to fix it:

```bash
cat > sql-injection-fix.py << 'EOF'
# VULNERABLE CODE (what Semgrep detected):
# query = f"SELECT * FROM users WHERE username = '{username}' AND password = '{password}'"
# cursor.execute(query)

# SECURE CODE (proper parameterized query):
cursor.execute("SELECT * FROM users WHERE username = ? AND password = ?", (username, password))
EOF

cat sql-injection-fix.py
```{{exec}}

## Security Gate Configuration

In a real CI/CD pipeline, you'd configure security gates based on Semgrep findings:

```bash
cat > security-gate-example.sh << 'EOF'
#!/bin/bash
# Example security gate logic

# Run Semgrep and save results
semgrep --config=auto --json vulnerable-app/ > semgrep-results.json

# Count critical findings
CRITICAL_COUNT=$(jq '[.results[] | select(.extra.severity=="ERROR")] | length' semgrep-results.json)

echo "Critical SAST findings: $CRITICAL_COUNT"

# Security gate: fail if any critical vulnerabilities found
if [ "$CRITICAL_COUNT" -gt 0 ]; then
    echo "SECURITY GATE FAILED: Critical vulnerabilities detected"
    echo "Please fix the following critical issues before deployment:"
    jq -r '.results[] | select(.extra.severity=="ERROR") | "- \(.check_id) in \(.path):\(.start.line)"' semgrep-results.json
    exit 1
else
    echo "SECURITY GATE PASSED: No critical vulnerabilities detected"
fi
EOF

chmod +x security-gate-example.sh
./security-gate-example.sh
```{{exec}}

As expected, our security gate fails because we have critical vulnerabilities!

## Easter Egg Clue #1 🕵️

Notice in the Semgrep results that there's a pattern in the admin endpoints. The vulnerable application has a special admin function that accepts serialized data. Combined with the hardcoded secret key, this might be more dangerous than it appears...

*Keep this in mind as we explore dependency vulnerabilities in the next step.*

## SAST Scan Summary

Let's generate a summary of our SAST findings:

```bash
echo "=== SAST SECURITY SCAN SUMMARY ==="
echo "Scan Tool: Semgrep"
echo "Target: VulnShop Application"
echo "Scan Date: $(date)"
echo ""
echo "FINDINGS:"
echo "- Total Issues: $(jq '.results | length' semgrep-results.json)"
echo "- Critical (ERROR): $(jq '[.results[] | select(.extra.severity=="ERROR")] | length' semgrep-results.json)" 
echo "- Warnings: $(jq '[.results[] | select(.extra.severity=="WARNING")] | length' semgrep-results.json)"
echo ""
echo "TOP CRITICAL ISSUES:"
jq -r '.results[] | select(.extra.severity=="ERROR") | "- \(.check_id): \(.extra.message | split(".")[0])"' semgrep-results.json
echo ""
echo "RECOMMENDATION: Fix all ERROR-level findings before deployment"
```{{exec}}

## Key Takeaways

From this SAST implementation, you've learned:

1. **SAST finds critical vulnerabilities** in source code before deployment
2. **Custom rules** can be created for organization-specific security requirements  
3. **Multiple output formats** support different CI/CD and security tools
4. **Security gates** can automatically block vulnerable code from reaching production
5. **Pattern-based detection** is more accurate than simple text searching

In the next step, you'll learn about the second pillar of DevSecOps security scanning: **dependency vulnerability scanning** with OWASP Dependency Check.

The combination of SAST + dependency scanning provides comprehensive coverage of application security risks!
=======
# Step 3: Static Application Security Testing (SAST) with Semgrep

## Understanding Static Application Security Testing

**Static Application Security Testing (SAST)** analyzes source code without executing the application to identify security vulnerabilities. Unlike dynamic testing that requires a running application, SAST provides:

- **Early detection** of vulnerabilities during development
- **Complete code coverage** including rarely executed paths  
- **Precise vulnerability location** with exact line numbers
- **Fast feedback** integrated into developer workflows
- **Scalable analysis** across large codebases

Think of SAST as having a security expert review every line of your code automatically, 24/7, without getting tired or missing patterns that human reviewers might overlook.

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

Before running our security scans, it's crucial to understand how Semgrep rules work. Rules are the heart of SAST - they define what security patterns to look for in your code. Let's examine the custom rules that have been prepared for our vulnerable application.

First, let's navigate back to the project root directory to access our configuration files:

```bash
cd ../
```{{exec}}

Now, let's examine the custom Semgrep rules that have been specifically created for this tutorial:

```bash
cat .semgrep.yml
```{{exec}}

**What you should see:** A YAML file containing several custom security rules designed to detect common vulnerabilities in Python web applications. Each rule follows a specific structure that tells Semgrep exactly what patterns to look for.

### Rule Anatomy Breakdown

Understanding rule structure is essential for creating effective security policies. Let's break down how Semgrep rules work by examining a typical SQL injection detection pattern:

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

**What this means:** The rule above uses "metavariables" (like $CURSOR and $VAR) that act as wildcards, allowing Semgrep to find SQL injection patterns regardless of variable names. This makes the rule both powerful and flexible.

## Running Comprehensive SAST Scans

Now we'll perform systematic security analysis using different Semgrep configurations. We'll start with our custom rules, then expand to community rules for broader coverage.

### Scan 1: Custom Rules Analysis

Our first scan will use the custom security rules we just examined. These rules are specifically tailored to catch the types of vulnerabilities present in our demo application:

```bash
semgrep --config=.semgrep.yml vulnerable-app/ --json > semgrep-custom-results.json
```{{exec}}

**What this command does:** This runs Semgrep using our custom rule file (`.semgrep.yml`) against the vulnerable application, outputting results in JSON format for easier processing.

Now let's format and display the results in a human-readable way:

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

**What you should see:** A detailed list of security vulnerabilities found by our custom rules. You should see findings like SQL injection, command injection, and insecure session handling - exactly the types of issues our demo application was designed to demonstrate.

### Scan 2: Community Security Rules

Next, let's expand our analysis using Semgrep's community-maintained security rules. These rules represent collective knowledge from security researchers worldwide:

```bash
semgrep --config=p/security-audit --config=p/secrets vulnerable-app/ --json > semgrep-community-results.json
```{{exec}}

**What this command does:** This runs two community rule sets:
- `p/security-audit`: General security vulnerability patterns
- `p/secrets`: Patterns that detect hardcoded secrets, API keys, and passwords

Now let's analyze the community rule findings to understand what additional vulnerabilities were discovered:

```bash
echo "Total findings: $(jq '.results | length' semgrep-community-results.json)"
echo ""
echo "Findings by severity:"
echo "• Critical: $(jq '[.results[] | select(.extra.severity=="ERROR")] | length' semgrep-community-results.json)"
echo "• Warning: $(jq '[.results[] | select(.extra.severity=="WARNING")] | length' semgrep-community-results.json)"
echo "• Info: $(jq '[.results[] | select(.extra.severity=="INFO")] | length' semgrep-community-results.json)"
```{{exec}}

**What you should see:** A summary showing the total number of vulnerabilities found by community rules, broken down by severity level. You'll likely see additional findings that our custom rules didn't catch, demonstrating the value of comprehensive rule coverage.

## Comprehensive Vulnerability Analysis

Now let's combine both scan results to get a complete picture of our application's security posture. This step demonstrates how multiple rule sets work together to provide comprehensive coverage:

```bash
jq -s 'map(.results // []) | add | {results: .}' \
   semgrep-custom-results.json semgrep-community-results.json > semgrep-combined-results.json

TOTAL_FINDINGS=$(jq '.results | length' semgrep-combined-results.json)
CRITICAL_COUNT=$(jq '[.results[] | select(.extra.severity=="ERROR")] | length' semgrep-combined-results.json)
WARNING_COUNT=$(jq '[.results[] | select(.extra.severity=="WARNING")] | length' semgrep-combined-results.json)

echo "Total Unique Vulnerabilities: $TOTAL_FINDINGS"
echo "Critical (ERROR): $CRITICAL_COUNT"
echo "Warning: $WARNING_COUNT"
echo ""
```{{exec}}

**What this command does:** The `jq` command merges the JSON results from both scans, removing duplicates, and then counts vulnerabilities by severity level.

**What you should see:** A consolidated summary showing the total number of unique vulnerabilities across both custom and community rules. This gives you the complete security picture of the application.

### Critical Vulnerability Deep Dive

Let's examine the critical vulnerabilities in detail. These are the findings that pose the highest risk and require immediate attention:

```bash
jq -r '.results[] | select(.extra.severity=="ERROR") | "
CRITICAL: \(.check_id)
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

**What this command does:** This filters the results to show only ERROR-level findings and provides context about the potential impact of each vulnerability type.

**What you should see:** Detailed information about each critical vulnerability, including its location and potential impact. This helps prioritize remediation efforts - for example, SQL injection and command injection both allow attackers to execute arbitrary code or access sensitive data.

## SAST Integration and Automation

Understanding different output formats is crucial for integrating SAST into your CI/CD pipeline. Let's explore the various ways Semgrep can present its findings:

### Command Line Integration Options

Different CI/CD systems and security tools expect different output formats. Here are the main options:

```bash
echo "Demonstrating different Semgrep output formats for CI/CD integration:"
echo ""
echo "1. JSON Format (for automation and custom processing):"
echo "   semgrep --config=auto --json vulnerable-app/"
echo ""
echo "2. SARIF Format (for GitHub Security tab integration):"
echo "   semgrep --config=auto --sarif vulnerable-app/"
echo ""
echo "3. GitLab SAST Format (for GitLab security features):"
echo "   semgrep --config=auto --gitlab-sast vulnerable-app/"
echo ""
echo "4. JUnit XML (for test integration and reporting):"
echo "   semgrep --config=auto --junit-xml vulnerable-app/"
```{{exec}}

**What this shows:** The different output formats available for integrating Semgrep into various CI/CD platforms and security tools. Each format serves a specific purpose in the DevSecOps toolchain.

### Security Gate Implementation

A security gate is a crucial component that automatically decides whether code can be deployed based on security scan results. Let's create a script that demonstrates this concept:

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
    echo "SECURITY GATE FAILED"
    echo "   Critical vulnerabilities detected: $CRITICAL_ISSUES"
    echo "   Build should be blocked in CI/CD pipeline"
    echo ""
    echo "Critical Issues:"
    jq -r '.results[] | select(.extra.severity=="ERROR") | "   • \(.check_id) (\(.path):\(.start.line))"' gate-scan-results.json
    exit 1
elif [ "$HIGH_ISSUES" -gt 5 ]; then
    echo "SECURITY GATE WARNING"
    echo "   High severity issues exceed threshold: $HIGH_ISSUES > 5"
    echo "   Consider reviewing before deployment"
    exit 1
else
    echo "SECURITY GATE PASSED"
    echo "   Security findings within acceptable limits"
    exit 0
fi
EOF

chmod +x sast-security-gate.sh
```{{exec}}

**What this script does:** This creates an automated security gate that:
1. Runs a Semgrep scan
2. Counts vulnerabilities by severity
3. Applies business logic to determine if the code can be deployed
4. Returns appropriate exit codes for CI/CD integration

The script implements a common security policy: zero tolerance for critical vulnerabilities, and a threshold of 5 for high-severity issues.

Now let's test our security gate with the vulnerable application:

```bash
./sast-security-gate.sh
```{{exec}}

**What you should see:** The security gate should **FAIL** because our intentionally vulnerable application contains critical security issues. You'll see a detailed breakdown of why the gate failed and which critical vulnerabilities were found.

This failure is expected and demonstrates how security gates prevent vulnerable code from being deployed to production.

## Advanced Semgrep Techniques

### Custom Rule Development

For organizations with specific security requirements, creating custom rules is essential. Let's create an advanced custom rule that demonstrates more sophisticated pattern matching:

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

**What this rule file contains:**
1. **dangerous-admin-operations**: A complex rule that detects when dangerous functions (like `subprocess.run` or `eval`) are called in admin contexts. This catches privilege escalation vulnerabilities.
2. **insecure-session-config**: A rule that uses regex patterns to detect weak session keys that are too short to be cryptographically secure.

These rules demonstrate advanced Semgrep features like metavariable patterns and regex matching.

Now let's test these advanced custom rules:

```bash
semgrep --config=advanced-custom-rules.yml vulnerable-app/ --json | jq -r '.results[] | "
Advanced Rule: \(.check_id)
Finding: \(.extra.message)
Location: \(.path):\(.start.line)
────────────────────────────────────────
"'
```{{exec}}

**What you should see:** Results from the advanced rules, showing any admin privilege escalation risks or weak session configurations found in the application.

### Performance and Optimization

In large codebases, scan performance becomes important. Let's demonstrate optimization techniques:

#### 1. Excluding files for faster scans:
```bash
echo "Running scan with file exclusions (faster for large codebases):"
semgrep --config=auto --exclude='*.log' --exclude='test_*' vulnerable-app/
```{{exec}}

**What this does:** Excludes log files and test files from scanning, which can significantly speed up scans in projects with many test files or large log directories.

#### 2. Using specific rule sets for targeted scanning:
```bash
echo "Running targeted security audit scan:"
semgrep --config=p/security-audit vulnerable-app/
```{{exec}}

**What you should see:** Results from only security-focused rules, which runs faster than comprehensive scans when you only need security findings.

#### 3. Performance measurement:
```bash
echo "Measuring scan performance:"
time semgrep --config=.semgrep.yml vulnerable-app/ --quiet >/dev/null
```{{exec}}

**What you should see:** Timing information showing how long the scan took. The `time` command shows real, user, and system time, helping you understand scan performance characteristics.

## SAST Implementation Summary

Let's create a comprehensive summary of what we've accomplished with our SAST implementation:

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

**What this summary shows:** A complete overview of our SAST implementation, including the number of vulnerabilities found and confirmation that all integration components are ready for production use.

## Key Achievements

Through this comprehensive SAST implementation with Semgrep, you have:

1. **Mastered SAST fundamentals** and understood how static analysis detects vulnerabilities before code execution
2. **Configured custom security rules** tailored to your application's specific security requirements and organizational policies
3. **Integrated community rules** for broader vulnerability coverage, leveraging the collective knowledge of security researchers
4. **Implemented security gates** that can automatically block deployments when critical vulnerabilities are detected
5. **Created automated workflows** ready for CI/CD pipeline integration with proper output formats
6. **Developed risk assessment capabilities** for vulnerability prioritization and impact analysis

Your SAST implementation provides the first pillar of comprehensive DevSecOps security scanning. The security gate you've created will prevent vulnerable code from reaching production, while the detailed vulnerability reports help developers understand and fix security issues quickly.

In the next steps, you'll add dependency vulnerability scanning and container security analysis to create complete security coverage across your entire application stack.
