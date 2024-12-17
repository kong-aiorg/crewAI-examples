#!/bin/bash

# pre-commit-scan.sh
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting pre-commit security scan...${NC}"

# Check if gitleaks is installed
if ! command -v gitleaks &> /dev/null; then
    echo -e "${RED}Error: gitleaks is not installed${NC}"
    echo "Install with: brew install gitleaks"
    exit 1
fi

# Run gitleaks
echo -e "${YELLOW}Running gitleaks scan...${NC}"

# Scan staged changes
SCAN_RESULTS=$(gitleaks detect --source . --verbose)

if [ $? -eq 1 ]; then
    echo -e "${RED}WARNING: Potential secrets found in code!${NC}"
    echo "$SCAN_RESULTS"
    echo -e "${RED}Please remove secrets before committing${NC}"
    exit 1
else
    echo -e "${GREEN}No secrets found - scan passed!${NC}"
fi
