#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VENV_NAME=".venv"
PYTHON_MIN_VERSION="3.9"
PYTHON_MAX_VERSION="3.13"
DEBUG=${DEBUG:-false}

# Function definitions
debug() {
    [ "$DEBUG" = "true" ] && echo -e "${BLUE}DEBUG: $1${NC}"
}

info() {
    echo -e "${YELLOW}$1${NC}"
}

success() {
    echo -e "${GREEN}$1${NC}"
}

error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

install_poetry() {
    info "Checking Poetry installation..."
    if ! command -v poetry &> /dev/null; then
        info "Installing Poetry..."
        curl -sSL https://install.python-poetry.org | python3 -
        export PATH="$HOME/.local/bin:$PATH"
    else
        success "Poetry is already installed"
    fi
}

configure_poetry() {
    info "Configuring Poetry..."
    poetry config virtualenvs.in-project true
    poetry config virtualenvs.create true
}

version_compare() {
    echo | awk -v v1="$1" -v v2="$2" '
    BEGIN {
        split(v1, a, ".")
        split(v2, b, ".")
        for (i=1; i<=3; i++) {
            if (a[i] < b[i]) { print "-1"; exit }
            if (a[i] > b[i]) { print "1"; exit }
        }
        print "0"
    }'
}

check_python_version() {
    local python_cmd=$1
    local version=$($python_cmd -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    debug "Checking Python version: $version"
    
    if [ $(version_compare "$version" "$PYTHON_MIN_VERSION") -lt 0 ]; then
        return 1
    fi
    
    if [ $(version_compare "$version" "$PYTHON_MAX_VERSION") -gt 0 ]; then
        info "Warning: Python $version detected. This script is tested up to Python $PYTHON_MAX_VERSION"
        read -p "Do you want to continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    return 0
}

find_python() {
    local commands=(
        "python3.9"
        "python3.10"
        "python3.11"
        "python3.12"
        "python3.13"
        "python3"
        "python"
    )
    
    for cmd in "${commands[@]}"; do
        if command -v $cmd >/dev/null 2>&1; then
            if check_python_version $cmd; then
                echo $cmd
                return 0
            fi
        fi
    done
    
    error "No suitable Python version found. Please install Python $PYTHON_MIN_VERSION-$PYTHON_MAX_VERSION"
}


update_dependencies() {
    info "Updating dependencies..."
    poetry update
    poetry install
    success "Dependencies updated successfully"
}

main() {
    info "Starting project setup..."
    

    
    # Install dependencies
    info "Installing project dependencies..."
    poetry install

    if [ "$DEV_MODE" = "true" ]; then
        poetry install --with dev
    fi
    
    # Print success message and instructions
    echo
    success "Project setup complete! 🎉"
    echo
    info "To activate the virtual environment:"
    echo "poetry shell"
    echo
    info "To run the application:"
    echo "poetry run python src/main.py"
    echo
  
    
  
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
