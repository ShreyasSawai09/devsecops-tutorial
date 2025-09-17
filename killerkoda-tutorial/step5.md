# Step 5: Container Image Scanning with Grype

In this step, you'll build the vulnerable application image and scan it for OS and package vulnerabilities using Grype.

## Build the image

```bash
cd devsecops-pipeline-tutorial/vulnerable-app
docker build -t vulnshop:workshop .
```

## Scan with Grype

```bash
grype vulnshop:workshop --output json > grype-results.json
```

- Review findings in `grype-results.json`
- Pay attention to severity levels and fix versions

## CI behavior

In CI, the pipeline fails for `severity-cutoff: high`. This means any High or Critical vulnerability fails the job. Results are uploaded as SARIF and shown in the repository Security tab.

When done, run the verifier for this step.

```bash
./killerkoda-tutorial/step5-verify.sh
```
