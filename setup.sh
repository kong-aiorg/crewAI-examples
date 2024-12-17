#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configurations
MIN_PYTHON_VERSION="3.9"
MAX_PYTHON_VERSION="3.13"
REQUIRED_PYTHON_VERSION="^3.9"
DEBUG=${DEBUG:-false}

# Function to print debug messages
debug() {
    if [ "$DEBUG" = "true" ]; then
        echo -e "${BLUE}DEBUG: $1${NC}"
    fi
}

# Function to print error messages
error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Function to print success messages
success() {
    echo -e "${GREEN}$1${NC}"
}

# Function to print info messages
info() {
    echo -e "${YELLOW}$1${NC}"
}

# Function to compare version numbers
version_compare() {
    if [[ $1 == $2 ]]; then
        echo "0"
        return
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            echo "1"
            return
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            echo "-1"
            return
        fi
    done
    echo "0"
}

# Check Python version and requirements
check_python() {
    info "Checking Python version..."
    
    # Check for python3 command
    if ! command -v python3 &> /dev/null; then
        error "Python 3 is not installed. Please install Python $MIN_PYTHON_VERSION or higher."
    fi
    
    # Get Python version
    python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    debug "Detected Python version: $python_version"
    
    # Compare with minimum version
    if [ $(version_compare "$python_version" "$MIN_PYTHON_VERSION") -lt 0 ]; then
        error "Python $MIN_PYTHON_VERSION or higher is required. Current version: $python_version"
    fi
    
    # Compare with maximum version and warn if higher
    if [ $(version_compare "$python_version" "$MAX_PYTHON_VERSION") -gt 0 ]; then
        info "Warning: You're using Python $python_version. This project is tested up to Python $MAX_PYTHON_VERSION"
        read -p "Do you want to continue? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            error "Installation cancelled by user"
        fi
    fi
    
    success "Python $python_version detected and compatible"
}

# Install Poetry with version check
install_poetry() {
    info "Installing Poetry..."
    
    if command -v poetry &> /dev/null; then
        poetry_version=$(poetry --version | awk '{print $3}')
        debug "Detected Poetry version: $poetry_version"
        success "Poetry is already installed (version $poetry_version)"
    else
        debug "Installing Poetry via installer script"
        curl -sSL https://install.python-poetry.org | python3 -
        if [ $? -ne 0 ]; then
            error "Failed to install Poetry"
        fi
        # Add Poetry to PATH
        export PATH="$HOME/.local/bin:$PATH"
        success "Poetry installation complete"
    fi
    
    # Verify installation
    if ! command -v poetry &> /dev/null; then
        error "Poetry installation failed or not in PATH"
    fi
}

# Configure Poetry with error handling
configure_poetry() {
    info "Configuring Poetry..."
    
    # Create virtual environment in project directory
    debug "Setting virtualenvs.in-project to true"
    poetry config virtualenvs.in-project true || error "Failed to configure virtualenvs.in-project"
    
    # Configure Python version
    debug "Updating Python version requirement in pyproject.toml"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/python = \".*\"/python = \"$REQUIRED_PYTHON_VERSION\"/" pyproject.toml || \
            error "Failed to update Python version in pyproject.toml"
    else
        sed -i "s/python = \".*\"/python = \"$REQUIRED_PYTHON_VERSION\"/" pyproject.toml || \
            error "Failed to update Python version in pyproject.toml"
    fi
    
    # Additional Poetry configurations
    poetry config virtualenvs.create true
    
    success "Poetry configuration complete"
}

# Install project dependencies with retry mechanism
install_dependencies() {
    info "Installing project dependencies..."
    
    if [ ! -f "pyproject.toml" ]; then
        error "pyproject.toml not found. Please ensure you're in the correct directory."
    fi
    
    max_attempts=3
    attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        debug "Installation attempt $attempt of $max_attempts"
        
        if poetry install; then
            success "Dependencies installation complete"
            return 0
        else
            if [ $attempt -eq $max_attempts ]; then
                error "Failed to install dependencies after $max_attempts attempts"
            else
                info "Retrying installation..."
                ((attempt++))
                sleep 2
            fi
        fi
    done
}

# Create project structure
create_project_structure() {
    info "Creating project structure..."
    
    directories=(
        "src/job_posting"
        "config"
        "tests"
        "logs"
        "data"
        "docs"
    )
    
    for dir in "${directories[@]}"; do
        debug "Creating directory: $dir"
        mkdir -p "$dir" || error "Failed to create directory: $dir"
        touch "$dir/__init__.py" 2>/dev/null
    done
    
    success "Project structure created"
}

# Backup existing configuration
backup_existing_config() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="backup_$timestamp"
    
    if [ -f "config/agents.yaml" ] || [ -f "config/tasks.yaml" ] || [ -f ".env" ]; then
        info "Backing up existing configuration..."
        mkdir -p "$backup_dir"
        cp config/*.yaml "$backup_dir/" 2>/dev/null
        cp .env "$backup_dir/" 2>/dev/null
        success "Backup created in $backup_dir"
    fi
}

# Create configuration files
create_config_files() {
    info "Setting up configuration files..."
    
    # Backup existing configuration
    backup_existing_config
    
    # Create config directory if it doesn't exist
    mkdir -p config
    
    # Create agents.yaml
    cat > config/agents.yaml << 'EOL'
research_agent:
  name: Research Agent
  role: Research specialist focusing on job market analysis
  goals:
    - Thoroughly analyze company culture and requirements
    - Identify key industry trends and standards
  backstory: An experienced research analyst with expertise in job market analysis

writer_agent:
  name: Writer Agent
  role: Content specialist for job descriptions
  goals:
    - Create compelling job descriptions
    - Ensure clarity and accuracy in content
  backstory: A professional writer with experience in HR communications

review_agent:
  name: Review Agent
  role: Quality assurance specialist
  goals:
    - Ensure accuracy and completeness of job postings
    - Verify alignment with company culture
  backstory: An experienced HR professional with expertise in job posting optimization
EOL

    # Create tasks.yaml
    cat > config/tasks.yaml << 'EOL'
research_company_culture_task:
  description: Research and analyze company culture and values
  expected_output: Detailed analysis of company culture and values

research_role_requirements_task:
  description: Research specific role requirements and industry standards
  expected_output: Comprehensive list of role requirements and qualifications

draft_job_posting_task:
  description: Create initial job posting draft
  expected_output: Complete job posting draft

review_and_edit_job_posting_task:
  description: Review and optimize job posting
  expected_output: Final, polished job posting

industry_analysis_task:
  description: Analyze industry trends and standards
  expected_output: Industry analysis report
EOL

    # Create .env file if it doesn't exist
    if [ ! -f ".env" ]; then
        cat > .env << 'EOL'
# API Keys
OPENAI_API_KEY=your_openai_api_key_here
SERPER_API_KEY=your_serper_api_key_here

# Configuration
DEBUG=True
LOG_LEVEL=INFO
EOL
    fi

    success "Configuration files created"
}

# Main installation process
main() {
    info "Starting installation process for CrewAI project..."
    
    # Check system requirements
    check_python
    
    # Check if pyenv is installed
    if [ -z "$(pyenv --version)" ]; then
    echo "Error: Pyenv is not installed."
    exit 1
    fi

    # Set the global Python version to 3.13.0
    pyenv global 3.13.0

    echo "Python 3.13.0 set globally"

    # Install and configure Poetry
    install_poetry
    configure_poetry
    
    # Set up project structure and configuration
    create_project_structure
    create_config_files
    
    # Install dependencies
    install_dependencies
    
    success "Installation complete! 🎉"
    echo
    info "Next steps:"
    echo "1. Update the .env file with your API keys"
    echo "2. Activate the virtual environment: poetry shell"
    echo "3. Run the application: poetry run evaluate"
    echo
    echo "For development:"
    echo "- Format code: poetry run black ."
    echo "- Run tests: poetry run pytest"
    echo "- Type checking: poetry run mypy src/"
    echo
}

# Allow script to be sourced without running main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
