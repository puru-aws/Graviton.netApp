#!/bin/bash
set -e

# CodeDeploy AfterInstall Hook
# This script installs .NET SDK and builds the application

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_status "=== CodeDeploy AfterInstall Hook ==="

# Change to application directory
cd /opt/graviton-bridge

# Function to detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        DISTRO="rhel"
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
    else
        DISTRO="unknown"
    fi
    
    print_status "Detected distribution: $DISTRO"
}

# Function to install .NET SDK
install_dotnet() {
    print_status "Installing .NET SDK..."
    
    case $DISTRO in
        "ubuntu"|"debian")
            print_status "Installing .NET SDK for Ubuntu/Debian..."
            
            # Get Ubuntu version for package configuration
            UBUNTU_VERSION=$(lsb_release -rs | cut -d. -f1,2 2>/dev/null || echo "20.04")
            
            # Download and install Microsoft package repository
            wget -q https://packages.microsoft.com/config/ubuntu/${UBUNTU_VERSION}/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
            sudo dpkg -i packages-microsoft-prod.deb
            rm packages-microsoft-prod.deb
            
            # Update package list and install .NET SDK (prioritize 10.0)
            sudo apt-get update
            sudo apt-get install -y apt-transport-https
            sudo apt-get install -y dotnet-sdk-10.0 || sudo apt-get install -y dotnet-sdk-8.0 || sudo apt-get install -y dotnet-sdk-7.0 || sudo apt-get install -y dotnet-sdk-6.0
            ;;
            
        "amzn"|"centos"|"rhel"|"fedora")
            print_status "Installing .NET SDK for Amazon Linux/CentOS/RHEL..."
            
            # For Amazon Linux, try different approaches based on version
            if [ "$DISTRO" = "amzn" ]; then
                print_status "Detected Amazon Linux - using Microsoft installation script for .NET 10.0"
                
                # Use the Microsoft installation script for Amazon Linux to get .NET 10.0
                wget -q https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
                chmod +x dotnet-install.sh
                
                # Install .NET 10.0 first, then fallback to older versions
                if ./dotnet-install.sh --channel 10.0; then
                    print_success "Successfully installed .NET 10.0"
                elif ./dotnet-install.sh --channel 8.0; then
                    print_success "Successfully installed .NET 8.0"
                elif ./dotnet-install.sh --channel 7.0; then
                    print_success "Successfully installed .NET 7.0"
                else
                    print_error "Failed to install .NET SDK via installation script"
                    rm dotnet-install.sh
                    exit 1
                fi
                
                # Add to PATH for current session and future sessions
                export PATH="$PATH:$HOME/.dotnet"
                echo 'export PATH="$PATH:$HOME/.dotnet"' >> ~/.bashrc
                
                # Create symlink for system-wide access
                sudo ln -sf $HOME/.dotnet/dotnet /usr/local/bin/dotnet
                
                rm dotnet-install.sh
            else
                # For CentOS/RHEL/Fedora, use package manager
                print_status "Using package manager for CentOS/RHEL/Fedora"
                
                # Add Microsoft package repository
                sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm
                
                if command -v dnf &> /dev/null; then
                    sudo dnf install -y dotnet-sdk-10.0 || sudo dnf install -y dotnet-sdk-8.0 || sudo dnf install -y dotnet-sdk-7.0 || sudo dnf install -y dotnet-sdk-6.0
                else
                    sudo yum install -y dotnet-sdk-10.0 || sudo yum install -y dotnet-sdk-8.0 || sudo yum install -y dotnet-sdk-7.0 || sudo yum install -y dotnet-sdk-6.0
                fi
            fi
            ;;
            
        *)
            print_warning "Unsupported distribution. Attempting generic installation..."
            # Try to install using the Microsoft installation script
            wget -q https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
            chmod +x dotnet-install.sh
            
            # Try .NET 10.0 first, then fallback to older versions
            if ./dotnet-install.sh --channel 10.0; then
                print_success "Successfully installed .NET 10.0"
            elif ./dotnet-install.sh --channel 8.0; then
                print_success "Successfully installed .NET 8.0"
            elif ./dotnet-install.sh --channel 7.0; then
                print_success "Successfully installed .NET 7.0"
            elif ./dotnet-install.sh --channel 6.0; then
                print_success "Successfully installed .NET 6.0"
            else
                print_error "Failed to install any .NET SDK version"
                rm dotnet-install.sh
                exit 1
            fi
            
            # Add to PATH
            export PATH="$PATH:$HOME/.dotnet"
            echo 'export PATH="$PATH:$HOME/.dotnet"' >> ~/.bashrc
            rm dotnet-install.sh
            ;;
    esac
}

# Function to verify .NET installation
verify_dotnet() {
    print_status "Verifying .NET installation..."
    
    if command -v dotnet &> /dev/null; then
        DOTNET_VERSION=$(dotnet --version)
        print_success ".NET SDK installed successfully. Version: $DOTNET_VERSION"
        return 0
    else
        print_error ".NET SDK installation failed or not found in PATH"
        return 1
    fi
}

# Function to install additional dependencies
install_dependencies() {
    print_status "Installing additional dependencies..."
    
    case $DISTRO in
        "ubuntu"|"debian")
            sudo apt-get update
            sudo apt-get install -y curl wget unzip lsof --skip-broken
            ;;
        "amzn"|"centos"|"rhel"|"fedora")
            if command -v dnf &> /dev/null; then
                sudo dnf install -y curl wget unzip lsof --skip-broken
            else
                sudo yum install -y curl wget unzip lsof --skip-broken
            fi
            ;;
    esac
}

# Function to build the application
build_application() {
    print_status "Building the .NET Graviton Compatibility Test Application..."
    
    # Check if we're in the right directory
    if [ ! -f "GravitonBridge.sln" ]; then
        print_error "GravitonBridge.sln not found in $(pwd)"
        ls -la
        exit 1
    fi
    
    # Restore NuGet packages
    print_status "Restoring NuGet packages..."
    dotnet restore
    
    # Build the solution
    print_status "Building the solution..."
    dotnet build --configuration Release
    
    print_success "Application built successfully!"
}

# Function to create systemd service
create_systemd_service() {
    print_status "Creating systemd service..."
    
    sudo tee /etc/systemd/system/graviton-bridge.service > /dev/null << EOF
[Unit]
Description=.NET Graviton Compatibility Test Application
After=network.target

[Service]
Type=notify
User=ec2-user
WorkingDirectory=/opt/graviton-bridge/src/GravitonBridge.Web
ExecStart=/usr/bin/dotnet run --configuration Release
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=graviton-bridge
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://0.0.0.0:5000
Environment=ASPNETCORE_FORWARDEDHEADERS_ENABLED=true

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable graviton-bridge
    
    print_success "Systemd service created and enabled"
}

# Main execution
main() {
    print_status "Starting installation process..."
    
    # Detect distribution
    detect_distro
    
    # Install dependencies
    install_dependencies
    
    # Check if .NET is already installed
    if command -v dotnet &> /dev/null; then
        EXISTING_VERSION=$(dotnet --version)
        print_status ".NET SDK already installed. Version: $EXISTING_VERSION"
    else
        install_dotnet
    fi
    
    # Verify installation
    if ! verify_dotnet; then
        print_error "Installation failed. Please check the error messages above."
        exit 1
    fi
    
    # Build application
    build_application
    
    # Create systemd service
    create_systemd_service
    
    print_success "Installation completed successfully!"
}

# Run main function
main "$@"