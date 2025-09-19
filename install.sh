#!/usr/bin/env bash
set -euo pipefail

# --- Colors for better visibility ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- Configuration ---
REPO_URL="https://github.com/HerodotusDev/herodotus-cloud-dev-cli"
INSTALL_DIR="${HOME}/.local/bin"
HERODOTUS_DIR="${HOME}/.herodotus"
VERSION="1.0.0"

# Function to detect OS and architecture
detect_platform() {
    local os arch
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(uname -m)
    
    case "$arch" in
        x86_64|amd64)
            arch="amd64"
            ;;
        arm64|aarch64)
            arch="arm64"
            ;;
        *)
            echo -e "${RED}ERROR:${NC} Unsupported architecture: $arch" >&2
            exit 1
            ;;
    esac
    
    echo "${os}_${arch}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if kubectl is installed
check_dependencies() {
    local missing_deps=()
    
    if ! command_exists kubectl; then
        missing_deps+=("kubectl")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${YELLOW}WARNING:${NC} Missing dependencies: ${missing_deps[*]}" >&2
        echo -e "Please install them before using Herodotus CLI" >&2
        echo ""
    fi
}

# Function to create directories
create_directories() {
    echo -e "${BLUE}Creating installation directories...${NC}"
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$HERODOTUS_DIR"
}

# Function to check git authentication
check_git_auth() {
    echo -e "${CYAN}Checking Git authentication...${NC}"
    
    # Test if we can access the private repository
    if git ls-remote "$REPO_URL" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Git authentication successful"
        return 0
    else
        echo -e "${RED}✗${NC} Git authentication failed"
        return 1
    fi
}

# Function to show authentication instructions
show_auth_instructions() {
    echo ""
    echo -e "${BOLD}${YELLOW}🔐 Authentication Required${NC}"
    echo ""
    echo -e "This is a private repository. You need to authenticate with GitHub first."
    echo ""
    echo -e "${BOLD}Option 1: GitHub CLI (Recommended)${NC}"
    echo -e "1. Install GitHub CLI: ${CYAN}brew install gh${NC} (macOS) or ${CYAN}sudo apt install gh${NC} (Ubuntu)"
    echo -e "2. Authenticate: ${CYAN}gh auth login${NC}"
    echo -e "3. Re-run this script: ${CYAN}curl -sSL https://gist.githubusercontent.com/your-username/your-gist-id/raw/install.sh | bash${NC}"
    echo ""
    echo -e "${BOLD}Option 2: Personal Access Token${NC}"
    echo -e "1. Create a token at: ${CYAN}https://github.com/settings/tokens${NC}"
    echo -e "2. Clone with token: ${CYAN}git clone https://YOUR_TOKEN@github.com/HerodotusDev/herodotus-cloud-dev-cli.git${NC}"
    echo -e "3. Or configure git: ${CYAN}git config --global credential.helper store${NC}"
    echo ""
    echo -e "${BOLD}Option 3: SSH Key${NC}"
    echo -e "1. Add your SSH key to GitHub: ${CYAN}https://github.com/settings/keys${NC}"
    echo -e "2. Use SSH URL: ${CYAN}git@github.com:HerodotusDev/herodotus-cloud-dev-cli.git${NC}"
    echo ""
    echo -e "${YELLOW}After authentication, re-run this installation script.${NC}"
}

# Function to download and install Herodotus CLI
install_herodotus() {
    echo -e "${BLUE}Downloading Herodotus CLI...${NC}"
    
    # Check git authentication first
    if ! check_git_auth; then
        show_auth_instructions
        exit 1
    fi
    
    # Create temporary directory
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf '$temp_dir'" EXIT
    
    # Clone the repository
    if command_exists git; then
        echo -e "${CYAN}Cloning repository...${NC}"
        git clone --depth 1 "$REPO_URL.git" "$temp_dir/herodotus-cli"
    else
        echo -e "${RED}ERROR:${NC} Git is required but not installed" >&2
        echo -e "Please install git first: ${CYAN}brew install git${NC} (macOS) or ${CYAN}sudo apt install git${NC} (Ubuntu)" >&2
        exit 1
    fi
    
    # Copy files to installation directory
    echo -e "${CYAN}Installing files...${NC}"
    cp "$temp_dir/herodotus-cli/herodotus" "$INSTALL_DIR/"
    cp -r "$temp_dir/herodotus-cli/commands" "$HERODOTUS_DIR/"
    
    # Make executable
    chmod +x "$INSTALL_DIR/herodotus"
    
    # Create version file
    echo "$VERSION" > "$HERODOTUS_DIR/version"
}

# Function to update PATH if needed
update_path() {
    local shell_rc
    shell_rc=""
    
    # Detect shell
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        shell_rc="${HOME}/.zshrc"
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        shell_rc="${HOME}/.bashrc"
    else
        # Try to detect from SHELL variable
        case "${SHELL:-}" in
            */zsh)
                shell_rc="${HOME}/.zshrc"
                ;;
            */bash)
                shell_rc="${HOME}/.bashrc"
                ;;
        esac
    fi
    
    if [[ -n "$shell_rc" && -f "$shell_rc" ]]; then
        # Check if PATH is already updated
        if ! grep -q "$INSTALL_DIR" "$shell_rc" 2>/dev/null; then
            echo -e "${YELLOW}Adding $INSTALL_DIR to PATH in $shell_rc${NC}"
            echo "" >> "$shell_rc"
            echo "# Herodotus CLI" >> "$shell_rc"
            echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$shell_rc"
            echo -e "${GREEN}✓${NC} PATH updated. Please run: ${CYAN}source $shell_rc${NC} or restart your terminal"
        else
            echo -e "${GREEN}✓${NC} PATH already configured"
        fi
    else
        echo -e "${YELLOW}WARNING:${NC} Could not detect shell configuration file" >&2
        echo -e "Please add ${CYAN}$INSTALL_DIR${NC} to your PATH manually" >&2
    fi
}

# Function to verify installation
verify_installation() {
    if [[ -f "$INSTALL_DIR/herodotus" && -x "$INSTALL_DIR/herodotus" ]]; then
        echo -e "${GREEN}✓${NC} Herodotus CLI installed successfully"
        echo -e "${GREEN}✓${NC} Installation directory: ${CYAN}$INSTALL_DIR${NC}"
        echo -e "${GREEN}✓${NC} Commands directory: ${CYAN}$HERODOTUS_DIR/commands${NC}"
        echo -e "${GREEN}✓${NC} Version: ${CYAN}$VERSION${NC}"
        return 0
    else
        echo -e "${RED}✗${NC} Installation failed" >&2
        return 1
    fi
}

# Function to show usage instructions
show_usage() {
    echo ""
    echo -e "${BOLD}${GREEN} Installation Complete!${NC}"
    echo ""
    echo -e "${BOLD}USAGE:${NC}"
    echo "    herodotus <command> [options]"
    echo ""
    echo -e "${BOLD}COMMANDS:${NC}"
    echo "    db forward    Start port-forwarding for PostgreSQL databases"
    echo "    db get        Extract database URLs from Kubernetes secrets"
    echo "    update        Update Herodotus CLI to latest version"
    echo "    version       Show version information"
    echo "    help          Show help message"
    echo ""
    echo -e "${BOLD}EXAMPLES:${NC}"
    echo "    herodotus db forward"
    echo "    herodotus db get"
    echo "    herodotus update"
    echo "    herodotus version"
    echo ""
    echo -e "${BOLD}NOTE:${NC} If 'herodotus' command is not found, please:"
    echo "    1. Restart your terminal, or"
    echo "    2. Run: ${CYAN}source ~/.zshrc${NC} (or ${CYAN}source ~/.bashrc${NC})"
    echo ""
    echo -e "${BOLD}UPDATE:${NC} To update to the latest version:"
    echo "    herodotus update"
}

# Main installation function
main() {
    echo -e "${BOLD}${PURPLE} Installing Herodotus Cloud Dev CLI${NC}"
    echo -e "${BOLD}Version:${NC} $VERSION"
    echo ""
    
    # Check dependencies
    check_dependencies
    
    # Create directories
    create_directories
    
    # Install Herodotus CLI
    install_herodotus
    
    # Update PATH
    update_path
    
    # Verify installation
    if verify_installation; then
        show_usage
    else
        echo -e "${RED}Installation failed. Please check the error messages above.${NC}" >&2
        exit 1
    fi
}

# Run main function
main "$@"
