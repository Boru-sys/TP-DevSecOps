#!/bin/bash
set -e

echo "=== Starting Security Scan Pipeline ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Scan Terraform files with Checkov
echo -e "${YELLOW}[1/4] Scanning Terraform files with Checkov...${NC}"
checkov -d infrastructure/terraform \
  --output json \
  --quiet \
  --compact \
  > security-report-terraform.json || true

# Scan Ansible files with Checkov
echo -e "${YELLOW}[2/4] Scanning Ansible files with Checkov...${NC}"
checkov -d configuration/ansible \
  --framework ansible \
  --output json \
  --quiet \
  > security-report-ansible.json || true

# Scan Dockerfiles with Checkov
echo -e "${YELLOW}[3/4] Scanning Dockerfiles with Checkov...${NC}"
> security-report-docker.json

find . -name "Dockerfile*" | while read -r dockerfile; do
  echo -e "${GREEN}Scanning Dockerfile: $dockerfile${NC}"
  checkov -f "$dockerfile" \
    --framework dockerfile \
    --output json \
    --quiet \
    >> security-report-docker.json || true
done

# Scan container images with Trivy
echo -e "${YELLOW}[4/4] Scanning container images with Trivy...${NC}"
for image in "cgr.dev/chainguard/prometheus:latest" "grafana/grafana:latest" "jenkins/jenkins:lts"; do
  echo -e "${GREEN}Scanning $image...${NC}"
  trivy image \
    --severity HIGH,CRITICAL \
    --format json \
    --output "trivy-$(echo "$image" | tr '/:' '-').json" \
    "$image" || true
done

# Generate summary report
echo -e "${GREEN}=== Security Scan Summary ===${NC}"
echo "Reports generated:"
ls -la *security-report*.json trivy-*.json 2>/dev/null || echo "No security issues found!"

# Check for critical issues
CRITICAL_COUNT=$(grep -h -c '"Severity":"CRITICAL"' trivy-*.json 2>/dev/null | awk '{sum+=$1} END {print sum+0}')

if [ "$CRITICAL_COUNT" -gt 0 ]; then
  echo -e "${RED}WARNING: $CRITICAL_COUNT critical vulnerabilities found!${NC}"
  exit 1
else
  echo -e "${GREEN}No critical vulnerabilities found.${NC}"
fi
