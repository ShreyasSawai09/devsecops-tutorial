# Step 4: Dependency Vulnerability Scanning with OWASP Dependency-Check

In this step, you'll scan third-party dependencies used by the vulnerable Flask app and learn how dependency vulnerabilities block the pipeline.

## Why dependency scanning?

- Finds known CVEs in libraries and transitive dependencies
- Detects vulnerable versions early to prevent supply-chain risks

## Run Dependency-Check locally

```bash
cd devsecops-pipeline-tutorial
# Generate HTML and JSON reports
dependency-check \
  --project VulnShop \
  --scan vulnerable-app/ \
  --format "HTML,JSON" \
  --out dep-check-reports
```

- Open `dep-check-reports/dependency-check-report.html` to explore findings
- Note CVSS scores and severities; map them to remediation actions

## Configure suppression and thresholds

The repository includes `dependency-check.properties` to customize scanning. In CI, we fail the build on CVSS ≥ 7.0.

Key options used in CI:

- `--failOnCVSS 7.0` fail pipeline on high/critical issues
- `--format HTML,JSON,SARIF` produce rich reports
- `--out reports/dependency-check` save artifacts for review

## What to observe

- Which packages are most risky?
- Are there direct upgrades or pins that fix issues?
- Do transitive dependencies require constraints?

When done, run the verifier for this step.

```bash
./killerkoda-tutorial/step4-verify.sh
```
