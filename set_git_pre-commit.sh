#!/bin/bash

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Create pre-commit hook
cat > .git/hooks/pre-commit << 'EOL'
#!/bin/bash

# Run security scan
./util/pre-commit-scan.sh

# Get the exit code
RESULT=$?

# If scan failed, prevent commit
if [ $RESULT -ne 0 ]; then
    echo "Commit blocked due to security concerns"
    exit 1
fi

exit 0
EOL

# Make the hook executable
chmod +x .git/hooks/pre-commit