#setup-security-scan.sh
#!/bin/bash
# setup-security-scan.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Setting up security scanning...${NC}"

# Install gitleaks if not present
if ! command -v gitleaks &> /dev/null; then
    echo "Installing gitleaks..."
    if command -v brew &> /dev/null; then
        brew install gitleaks
    else
        echo -e "${RED}Please install Homebrew or gitleaks manually${NC}"
        exit 1
    fi
fi

# Create pre-commit scan script
cat > pre-commit-scan.sh << 'EOL'
#!/bin/bash
# pre-commit-scan.sh content here
# ... (paste the content from the first script)
EOL

chmod +x pre-commit-scan.sh

# Create gitleaks config
cat > .gitleaks.toml << 'EOL'
# .gitleaks.toml content here
# ... (paste the content from the second file)
EOL

# Set up pre-commit hook
mkdir -p .git/hooks
cat > .git/hooks/pre-commit << 'EOL'
#!/bin/bash
# pre-commit hook content here
# ... (paste the content from the third script)
EOL

chmod +x .git/hooks/pre-commit

echo -e "${GREEN}Security scanning setup complete!${NC}"
echo -e "${YELLOW}Testing configuration...${NC}"

# Test the setup
gitleaks detect --source . --verbose

echo -e "${GREEN}Setup complete! Pre-commit hooks will now scan for secrets${NC}"
