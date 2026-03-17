#!/bin/bash
set -e

echo "=== GitOps Validation ==="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check Git status
echo -e "${YELLOW}1. Checking Git status...${NC}"
if [ -z "$(git status --porcelain)" ]; then
  echo -e "${GREEN}Working directory clean${NC}"
else
  echo -e "${RED}⚠ Uncommitted changes detected${NC}"
  git status --short
fi

# Validate Terraform
echo -e "${YELLOW}2. Validating Terraform...${NC}"
cd infrastructure/terraform || exit 1

terraform fmt -check
terraform validate

cd - > /dev/null

# Validate Ansible
echo -e "${YELLOW}3. Validating Ansible...${NC}"
ansible-playbook configuration/ansible/playbook.yml --syntax-check

# Check Docker resources
echo -e "${YELLOW}4. Checking Docker resources...${NC}"

echo -e "\n${GREEN}Containers:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n${GREEN}Networks:${NC}"
docker network ls | grep monitoring || echo "No monitoring network found"

echo -e "\n${GREEN}Volumes:${NC}"
docker volume ls | grep -E "prometheus|grafana" || echo "No volumes found"

echo -e "\n${GREEN}=== Validation Complete ===${NC}"
