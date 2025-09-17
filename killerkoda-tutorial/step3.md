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