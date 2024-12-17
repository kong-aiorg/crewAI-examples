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

create_pyproject_toml() {
    info "Creating pyproject.toml..."
    cat > pyproject.toml << EOL
[tool.poetry]
name = "crewai-example"
version = "0.1.0"
description = "CrewAI example project"
authors = ["Your Name <your.email@example.com>"]
readme = "README.md"

[tool.poetry.dependencies]
python = "^3.9"
crewai = "^0.11.0"
crewai-tools = "^0.0.9"
langchain = "^0.1.0"
openai = "^1.0.0"
python-dotenv = "^1.0.0"
PyYAML = "^6.0.1"
requests = "^2.31.0"
beautifulsoup4 = "^4.12.2"

[tool.poetry.group.dev.dependencies]
black = "^23.12.1"
pylint = "^3.0.3"
pytest = "^7.4.3"
mypy = "^1.7.1"
pytest-cov = "^4.1.0"
isort = "^5.13.2"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"

[tool.black]
line-length = 88
include = '\.pyi?$'

[tool.isort]
profile = "black"
multi_line_output = 3
include_trailing_comma = true
force_grid_wrap = 0
use_parentheses = true
line_length = 88

[tool.mypy]
python_version = "3.9"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
check_untyped_defs = true

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
addopts = "--verbose -ra -q"
EOL
    success "Created pyproject.toml"
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

setup_env_file() {
    if [ ! -f .env ]; then
        info "Creating .env file..."
        cat > .env << EOL
# OpenAI API Key (Required)
OPENAI_API_KEY=your_openai_api_key_here

# Optional API Keys
SERPER_API_KEY=your_serper_api_key_here
BROWSERLESS_API_KEY=your_browserless_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Configuration
DEBUG=False
LOG_LEVEL=INFO
ENVIRONMENT=development

# Model Configuration
DEFAULT_MODEL=gpt-4
FALLBACK_MODEL=gpt-3.5-turbo
EOL
        success "Created .env file (please update with your API keys)"
    else
        info ".env file already exists"
    fi
}

setup_project_structure() {
    info "Setting up project structure..."
    
    # Create directories
    mkdir -p src/job_posting tests config docs

    # Create __init__.py files
    touch src/__init__.py
    touch src/job_posting/__init__.py
    touch tests/__init__.py

    # Create basic test file
    cat > tests/test_basic.py << EOL
def test_import():
    try:
        from src.job_posting import crew
        assert True
    except ImportError:
        assert False, "Failed to import crew module"
EOL

    success "Project structure created"
}

cleanup_old_env() {
    if [ -d "$VENV_NAME" ]; then
        info "Found existing virtual environment"
        read -p "Do you want to remove the existing virtual environment? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$VENV_NAME"
            success "Old virtual environment removed"
        else
            error "Setup cancelled by user"
        fi
    fi
}

update_dependencies() {
    info "Updating dependencies..."
    poetry update
    poetry install
    success "Dependencies updated successfully"
}

main() {
    info "Starting project setup..."
    
    # Parse command line arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --update) UPDATE_ONLY=true ;;
            --dev) DEV_MODE=true ;;
            --debug) DEBUG=true ;;
            *) error "Unknown parameter: $1" ;;
        esac
        shift
    done

    # If update only, just update dependencies and exit
    if [ "$UPDATE_ONLY" = "true" ]; then
        if [ ! -f "pyproject.toml" ]; then
            error "pyproject.toml not found. Cannot update dependencies."
        fi
        install_poetry
        update_dependencies
        exit 0
    fi

    # Find suitable Python version
    PYTHON_CMD=$(find_python)
    
    # Install and configure Poetry
    install_poetry
    configure_poetry
    
    # Clean up old environment if exists
    cleanup_old_env
    
    # Create project files
    create_pyproject_toml
    setup_env_file
    setup_project_structure
    
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
    info "To update dependencies:"
    echo "./SetVenv.sh --update"
    echo
    info "Important next steps:"
    echo "1. Update the .env file with your API keys"
    echo "2. Review and update pyproject.toml as needed"
    echo "3. Run 'poetry install' after making changes to pyproject.toml"
    
    if [ "$DEV_MODE" = "true" ]; then
        echo
        info "Development tools available:"
        echo "- black: poetry run black ."
        echo "- pylint: poetry run pylint src/"
        echo "- pytest: poetry run pytest"
        echo "- mypy: poetry run mypy src/"
    fi
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
