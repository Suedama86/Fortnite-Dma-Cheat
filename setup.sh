#!/bin/bash

# Quick Setup Script for Fortnite DMA with Memflow Backend
# This script automates the initial setup process

set -e

echo "=================================="
echo "Fortnite DMA Quick Setup Script"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root. Some operations may require non-root user."
    fi
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if [ -f /etc/debian_version ]; then
            DISTRO="debian"
        elif [ -f /etc/redhat-release ]; then
            DISTRO="redhat"
        else
            DISTRO="unknown"
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
        DISTRO="windows"
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    print_status "Detected OS: $OS ($DISTRO)"
}

# Install dependencies for Linux
install_linux_deps() {
    print_status "Installing Linux dependencies..."
    
    if [ "$DISTRO" = "debian" ]; then
        sudo apt update
        sudo apt install -y \
            build-essential \
            cmake \
            git \
            pkg-config \
            curl \
            wget \
            libssl-dev \
            libglib2.0-dev
    elif [ "$DISTRO" = "redhat" ]; then
        sudo yum groupinstall -y "Development Tools"
        sudo yum install -y \
            cmake \
            git \
            pkg-config \
            curl \
            wget \
            openssl-devel \
            glib2-devel
    else
        print_warning "Unknown Linux distribution. Please install dependencies manually."
        return
    fi
    
    print_success "Linux dependencies installed"
}

# Install Rust and Cargo
install_rust() {
    print_status "Checking for Rust installation..."
    
    if command -v cargo &> /dev/null; then
        print_success "Rust already installed: $(cargo --version)"
        return
    fi
    
    print_status "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
    
    print_success "Rust installed: $(cargo --version)"
}

# Install Memflow
install_memflow() {
    print_status "Installing Memflow framework..."
    
    # Check if memflow is already installed
    if command -v memflow &> /dev/null; then
        print_success "Memflow already installed: $(memflow --version)"
        return
    fi
    
    # Install memflow CLI
    cargo install memflow-cli --force
    
    # Install QEMU connector
    cargo install memflow-qemu-procfs --force
    
    # Create memflow config directory
    mkdir -p ~/.config/memflow
    
    # Create basic configuration
    cat > ~/.config/memflow/config.toml << EOF
[connectors.qemu-procfs]
proc_path = "/proc"

[inventory.qemu-vms]
connector = "qemu-procfs"
args = ""
EOF
    
    print_success "Memflow framework installed"
}

# Configure project
configure_project() {
    print_status "Configuring project..."
    
    # Copy configuration template
    if [ ! -f "config.json" ]; then
        cp config.template.json config.json
        print_status "Created config.json from template"
    fi
    
    # Create build directory
    mkdir -p build
    
    print_success "Project configured"
}

# Build project
build_project() {
    print_status "Building project..."
    
    cd build
    
    if [ "$OS" = "linux" ]; then
        cmake .. -DCMAKE_BUILD_TYPE=Release -DUSE_MEMFLOW_BACKEND=ON
    else
        cmake .. -DCMAKE_BUILD_TYPE=Release
    fi
    
    make -j$(nproc 2>/dev/null || echo 4)
    
    cd ..
    
    print_success "Project built successfully"
}

# Setup development environment
setup_dev_environment() {
    print_status "Setting up development environment..."
    
    # Create .vscode directory if it doesn't exist
    mkdir -p .vscode
    
    # Create VS Code settings for GitHub Copilot
    cat > .vscode/settings.json << EOF
{
    "github.copilot.enable": {
        "*": true,
        "yaml": false,
        "plaintext": false
    },
    "github.copilot.advanced": {
        "length": 500,
        "temperature": 0.1,
        "top_p": 1,
        "indentationMode": "tabCompletion"
    },
    "C_Cpp.intelliSenseEngine": "Default",
    "C_Cpp.default.cppStandard": "c++17",
    "C_Cpp.default.compilerPath": "$(which g++ || which clang++)",
    "files.associations": {
        "*.h": "cpp",
        "*.hpp": "cpp"
    }
}
EOF
    
    # Create .copilotignore
    cat > .copilotignore << EOF
*.key
*.cert
auth.hpp
keyauth/
*.dll
*.exe
*.so
*.dylib
build/
.vs/
.vscode/
node_modules/
*.log
EOF
    
    # Create .gitignore if it doesn't exist
    if [ ! -f ".gitignore" ]; then
        cat > .gitignore << EOF
# Build artifacts
build/
.vs/
*.vcxproj.user
*.sln.docstates

# Configuration files (keep template)
config.json

# Logs
*.log
*.tmp

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Sensitive files
*.key
*.cert
auth.hpp
EOF
    fi
    
    print_success "Development environment configured"
}

# Check prerequisites for Proxmox setup
check_proxmox_prereqs() {
    print_status "Checking Proxmox prerequisites..."
    
    # Check if running on Proxmox host
    if [ -f /etc/pve/local/pve-ssl.pem ]; then
        print_success "Proxmox VE detected"
        PROXMOX_HOST=true
    else
        print_warning "Not running on Proxmox host. For VM setup, refer to PROXMOX_SETUP_GUIDE.md"
        PROXMOX_HOST=false
    fi
    
    # Check for virtualization support
    if [ "$OS" = "linux" ]; then
        if grep -q "vmx\|svm" /proc/cpuinfo; then
            print_success "CPU virtualization support detected"
        else
            print_warning "CPU virtualization support not detected or not enabled"
        fi
    fi
}

# Main setup function
main() {
    echo
    print_status "Starting setup process..."
    
    check_root
    detect_os
    
    if [ "$OS" = "linux" ]; then
        install_linux_deps
        install_rust
        install_memflow
        check_proxmox_prereqs
    else
        print_warning "Windows detected. Please follow the Windows setup instructions in PROXMOX_SETUP_GUIDE.md"
        print_warning "This script is primarily for Linux/Proxmox host setup."
    fi
    
    configure_project
    setup_dev_environment
    
    if [ "$OS" = "linux" ]; then
        build_project
    fi
    
    echo
    print_success "Setup completed successfully!"
    echo
    echo "Next steps:"
    echo "1. Review and edit config.json for your environment"
    echo "2. Read PROXMOX_SETUP_GUIDE.md for detailed VM setup"
    echo "3. Read MEMFLOW_INTEGRATION.md for backend integration"
    echo "4. Install GitHub Copilot extension in your editor"
    echo
    
    if [ "$PROXMOX_HOST" = true ]; then
        echo "Proxmox-specific next steps:"
        echo "1. Follow PROXMOX_SETUP_GUIDE.md to create Windows VM"
        echo "2. Configure VM for DMA access"
        echo "3. Install the project in the Windows VM"
        echo
    fi
    
    print_status "Setup script completed"
}

# Run main function
main "$@"