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
                print_status "Detected Amazon Linux - trying multiple installation methods"
                
                # First try package manager for better compatibility
                print_status "Attempting package manager installation first..."
                if sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm 2>/dev/null; then
                    if sudo yum install -y dotnet-sdk-8.0 2>/dev/null; then
                        print_success "Successfully installed .NET 8.0 via package manager"
                        return 0
                    elif sudo yum install -y dotnet-sdk-6.0 2>/dev/null; then
                        print_success "Successfully installed .NET 6.0 via package manager"
                        return 0
                    fi
                fi
                
                print_status "Package manager failed, trying Microsoft installation script..."
                # Use the Microsoft installation script for Amazon Linux
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
                export PATH="$HOME/.dotnet:$PATH"
                echo 'export PATH="$HOME/.dotnet:$PATH"' >> ~/.bashrc
                
                # Test the installation before creating symlink
                print_status "Testing .NET installation..."
                
                # Set ICU environment for testing if needed
                if [ -n "${DOTNET_SYSTEM_GLOBALIZATION_INVARIANT:-}" ]; then
                    export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
                fi
                
                if $HOME/.dotnet/dotnet --version >/dev/null 2>&1; then
                    print_success ".NET installation is working"
                    
                    # Create symlink for system-wide access
                    print_status "Creating system-wide dotnet symlink..."
                    sudo ln -sf $HOME/.dotnet/dotnet /usr/local/bin/dotnet
                    
                    # Verify the symlink works
                    if /usr/local/bin/dotnet --version >/dev/null 2>&1; then
                        print_success "Dotnet symlink created successfully"
                    else
                        print_warning "Symlink failed, removing it and using direct path"
                        sudo rm -f /usr/local/bin/dotnet
                    fi
                else
                    print_error ".NET installation is not working properly"
                    print_status "Attempting to diagnose the issue..."
                    
                    # Check if the dotnet binary exists and is executable
                    if [ -f "$HOME/.dotnet/dotnet" ]; then
                        print_status "Dotnet binary exists, checking permissions..."
                        ls -la $HOME/.dotnet/dotnet
                        
                        # Check if it's the right architecture
                        print_status "Checking binary architecture..."
                        file $HOME/.dotnet/dotnet || true
                        
                        # Try to get more detailed error
                        print_status "Attempting to run dotnet with error output..."
                        $HOME/.dotnet/dotnet --version 2>&1 || true
                    else
                        print_error "Dotnet binary not found at $HOME/.dotnet/dotnet"
                    fi
                    
                    # Try alternative installation method
                    print_status "Trying alternative installation method..."
                    rm -rf $HOME/.dotnet
                    
                    # Try installing .NET 8.0 instead of 10.0 for better compatibility
                    if ./dotnet-install.sh --channel 8.0; then
                        print_success "Successfully installed .NET 8.0 as fallback"
                        export PATH="$HOME/.dotnet:$PATH"
                        
                        # Test again
                        if $HOME/.dotnet/dotnet --version >/dev/null 2>&1; then
                            print_success ".NET 8.0 installation is working"
                            sudo ln -sf $HOME/.dotnet/dotnet /usr/local/bin/dotnet
                        else
                            print_error "Even .NET 8.0 installation failed"
                            exit 1
                        fi
                    else
                        print_error "Alternative installation also failed"
                        exit 1
                    fi
                fi
                
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
    
    # Try multiple ways to find and test dotnet
    DOTNET_PATHS=(
        "$(which dotnet 2>/dev/null || echo '')"
        "/usr/local/bin/dotnet"
        "$HOME/.dotnet/dotnet"
        "/usr/bin/dotnet"
    )
    
    for dotnet_path in "${DOTNET_PATHS[@]}"; do
        if [ -n "$dotnet_path" ] && [ -f "$dotnet_path" ]; then
            print_status "Testing dotnet at: $dotnet_path"
            
            # Test if it can run without crashing
            if timeout 10 "$dotnet_path" --version >/dev/null 2>&1; then
                DOTNET_VERSION=$("$dotnet_path" --version 2>/dev/null || echo "unknown")
                print_success ".NET SDK verified successfully. Version: $DOTNET_VERSION"
                print_status "Working dotnet path: $dotnet_path"
                
                # Ensure this path is in the system PATH
                if [ "$dotnet_path" != "$(which dotnet 2>/dev/null)" ]; then
                    print_status "Adding $dotnet_path to PATH"
                    export PATH="$(dirname "$dotnet_path"):$PATH"
                fi
                
                return 0
            else
                print_warning "Dotnet at $dotnet_path failed to run properly"
                
                # Show more details about the failure
                print_status "Detailed error for $dotnet_path:"
                timeout 5 "$dotnet_path" --version 2>&1 || print_status "Command timed out or crashed"
            fi
        fi
    done
    
    print_error ".NET SDK installation failed - no working dotnet found"
    print_status "Available dotnet files:"
    find /usr -name "dotnet" -type f 2>/dev/null || true
    find $HOME -name "dotnet" -type f 2>/dev/null || true
    return 1
}

# Function to install additional dependencies
install_dependencies() {
    print_status "Installing additional dependencies..."
    
    case $DISTRO in
        "ubuntu"|"debian")
            sudo apt-get update
            sudo apt-get install -y curl wget unzip lsof libicu-dev --skip-broken
            ;;
        "amzn"|"centos"|"rhel"|"fedora")
            if command -v dnf &> /dev/null; then
                # For newer systems with dnf
                sudo dnf install -y curl wget unzip lsof libicu --skip-broken
            else
                # For Amazon Linux and older systems with yum
                print_status "Installing ICU libraries for .NET compatibility..."
                sudo yum install -y curl wget unzip lsof --skip-broken
                
                # Install ICU libraries - different package names for different versions
                if sudo yum install -y libicu 2>/dev/null; then
                    print_success "Installed libicu"
                elif sudo yum install -y icu 2>/dev/null; then
                    print_success "Installed icu"
                elif sudo yum install -y libicu-devel 2>/dev/null; then
                    print_success "Installed libicu-devel"
                else
                    print_warning "Could not install ICU via package manager, trying alternative..."
                    
                    # For Amazon Linux, try different approaches based on version
                    if [ "$DISTRO" = "amzn" ]; then
                        print_status "Trying Amazon Linux specific ICU installation..."
                        
                        # Check Amazon Linux version
                        AL_VERSION=$(grep VERSION_ID /etc/os-release | cut -d'"' -f2 | cut -d'.' -f1)
                        print_status "Amazon Linux version: $AL_VERSION"
                        
                        if [ "$AL_VERSION" = "2023" ]; then
                            # Amazon Linux 2023
                            print_status "Installing ICU for Amazon Linux 2023..."
                            sudo dnf install -y libicu 2>/dev/null || \
                            sudo dnf install -y icu 2>/dev/null || \
                            sudo yum install -y libicu 2>/dev/null || true
                        else
                            # Amazon Linux 2 or older
                            print_status "Installing ICU for Amazon Linux 2..."
                            sudo amazon-linux-extras install -y epel 2>/dev/null || true
                            sudo yum install -y libicu 2>/dev/null || \
                            sudo yum install -y icu 2>/dev/null || true
                        fi
                        
                        # Final check and fallback to invariant culture
                        if ! ldconfig -p | grep -q libicu; then
                            print_warning "ICU libraries still not found, configuring invariant culture mode"
                            export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
                            echo 'export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1' >> ~/.bashrc
                            
                            # Also add to current session
                            export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
                        else
                            print_success "ICU libraries successfully installed"
                        fi
                    fi
                fi
            fi
            ;;
    esac
    
    # Verify ICU installation
    print_status "Verifying ICU libraries..."
    if ldconfig -p | grep -q libicu; then
        print_success "ICU libraries are available"
        ldconfig -p | grep libicu | head -3
    else
        print_warning "ICU libraries not found, setting invariant culture mode"
        export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
        echo 'export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1' >> ~/.bashrc
    fi
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
    
    # Clean any existing build artifacts
    print_status "Cleaning previous build artifacts..."
    dotnet clean || true
    
    # Remove obj and bin directories to ensure clean build
    find . -name "obj" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "bin" -type d -exec rm -rf {} + 2>/dev/null || true
    
    # Restore NuGet packages
    print_status "Restoring NuGet packages..."
    dotnet restore --verbosity minimal
    
    # Build the solution
    print_status "Building the solution..."
    dotnet build --configuration Release --verbosity minimal
    
    print_success "Application built successfully!"
}

# Function to create systemd service
create_systemd_service() {
    print_status "Creating systemd service..."
    
    # Find the actual dotnet path
    DOTNET_PATH=$(which dotnet)
    if [ -z "$DOTNET_PATH" ]; then
        # If not in PATH, check common locations
        if [ -f "/usr/local/bin/dotnet" ]; then
            DOTNET_PATH="/usr/local/bin/dotnet"
        elif [ -f "/home/ec2-user/.dotnet/dotnet" ]; then
            DOTNET_PATH="/home/ec2-user/.dotnet/dotnet"
        else
            print_error "Could not find dotnet executable"
            exit 1
        fi
    fi
    
    print_status "Using dotnet path: $DOTNET_PATH"
    
    # Check if we need invariant culture mode
    ICU_ENV=""
    if [ -n "${DOTNET_SYSTEM_GLOBALIZATION_INVARIANT:-}" ]; then
        ICU_ENV="Environment=DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1"
        print_status "Adding invariant culture mode to systemd service"
    fi
    
    sudo tee /etc/systemd/system/graviton-bridge.service > /dev/null << EOF
[Unit]
Description=.NET Graviton Compatibility Test Application
After=network.target

[Service]
Type=simple
User=ec2-user
Group=ec2-user
WorkingDirectory=/opt/graviton-bridge/src/GravitonBridge.Web
ExecStart=$DOTNET_PATH run --configuration Release
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=graviton-bridge
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://0.0.0.0:5000
Environment=ASPNETCORE_FORWARDEDHEADERS_ENABLED=true
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/ec2-user/.dotnet
${ICU_ENV}

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable graviton-bridge
    
    print_success "Systemd service created and enabled with dotnet path: $DOTNET_PATH"
}

# Function to fix permissions
fix_permissions() {
    print_status "Fixing file permissions..."
    
    # Ensure ec2-user owns all files in the deployment directory
    sudo chown -R ec2-user:ec2-user /opt/graviton-bridge
    
    # Set proper permissions for directories
    sudo find /opt/graviton-bridge -type d -exec chmod 755 {} \;
    
    # Set proper permissions for files
    sudo find /opt/graviton-bridge -type f -exec chmod 644 {} \;
    
    # Make shell scripts executable
    sudo find /opt/graviton-bridge/scripts -name "*.sh" -exec chmod 755 {} \;
    
    print_success "Permissions fixed successfully"
}

# Main execution
main() {
    print_status "Starting installation process..."
    
    # Fix permissions first
    fix_permissions
    
    # Detect distribution
    detect_distro
    
    # Install dependencies (including ICU) BEFORE .NET installation
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
    
    # Additional verification - test dotnet in the application directory
    print_status "Testing dotnet in application directory..."
    cd /opt/graviton-bridge
    
    # Find the working dotnet path
    WORKING_DOTNET=""
    for dotnet_path in "$(which dotnet 2>/dev/null || echo '')" "/usr/local/bin/dotnet" "$HOME/.dotnet/dotnet"; do
        if [ -n "$dotnet_path" ] && [ -f "$dotnet_path" ]; then
            if timeout 10 "$dotnet_path" --info >/dev/null 2>&1; then
                WORKING_DOTNET="$dotnet_path"
                break
            fi
        fi
    done
    
    if [ -n "$WORKING_DOTNET" ]; then
        print_success "Dotnet is working in application directory using: $WORKING_DOTNET"
        
        # Test basic dotnet commands
        print_status "Testing basic dotnet functionality..."
        if timeout 15 "$WORKING_DOTNET" --list-sdks >/dev/null 2>&1; then
            print_success "Dotnet SDK list command works"
        else
            print_warning "Dotnet SDK list command failed, but basic dotnet works"
        fi
    else
        print_error "Dotnet is not working in application directory"
        print_status "PATH: $PATH"
        print_status "Which dotnet: $(which dotnet || echo 'not found')"
        print_status "Available dotnet files:"
        find /usr -name "dotnet" -type f 2>/dev/null | head -5 || true
        find $HOME -name "dotnet" -type f 2>/dev/null | head -5 || true
        
        # Try to diagnose the core dump issue
        print_status "Checking system compatibility..."
        uname -a
        print_status "Checking available libraries..."
        ldd /usr/local/bin/dotnet 2>/dev/null | head -10 || true
        
        exit 1
    fi
    
    # Build application
    build_application
    
    # Verify the build output
    print_status "Verifying build output..."
    if [ -f "/opt/graviton-bridge/src/GravitonBridge.Web/bin/Release/net10.0/GravitonBridge.Web.dll" ]; then
        print_success "Application DLL found"
    else
        print_error "Application DLL not found after build"
        find /opt/graviton-bridge -name "*.dll" -type f | head -5
        exit 1
    fi
    
    # Create systemd service
    create_systemd_service
    
    print_success "Installation completed successfully!"
}

# Run main function
main "$@"