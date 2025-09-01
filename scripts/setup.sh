#!/bin/bash

# .NET Graviton Compatibility Test Application Setup Script
# This script automates the installation and setup process for Linux systems

set -e  # Exit on any error

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
            UBUNTU_VERSION=$(lsb_release -rs | cut -d. -f1,2)
            if [ -z "$UBUNTU_VERSION" ]; then
                UBUNTU_VERSION="20.04"  # Default fallback
            fi
            
            # Download and install Microsoft package repository
            wget -q https://packages.microsoft.com/config/ubuntu/${UBUNTU_VERSION}/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
            sudo dpkg -i packages-microsoft-prod.deb
            rm packages-microsoft-prod.deb
            
            # Update package list and install .NET SDK
            sudo apt-get update
            sudo apt-get install -y apt-transport-https
            sudo apt-get install -y dotnet-sdk-8.0 || sudo apt-get install -y dotnet-sdk-7.0 || sudo apt-get install -y dotnet-sdk-6.0
            ;;
            
        "centos"|"rhel"|"fedora")
            print_status "Installing .NET SDK for CentOS/RHEL/Amazon Linux..."
            
            # Add Microsoft package repository
            if [ "$DISTRO" = "amzn" ]; then
                # Amazon Linux
                sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm
                sudo yum install -y dotnet-sdk-8.0 || sudo yum install -y dotnet-sdk-7.0 || sudo yum install -y dotnet-sdk-6.0
            else
                # CentOS/RHEL/Fedora
                sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm
                if command -v dnf &> /dev/null; then
                    sudo dnf install -y dotnet-sdk-8.0 || sudo dnf install -y dotnet-sdk-7.0 || sudo dnf install -y dotnet-sdk-6.0
                else
                    sudo yum install -y dotnet-sdk-8.0 || sudo yum install -y dotnet-sdk-7.0 || sudo yum install -y dotnet-sdk-6.0
                fi
            fi
            ;;
            
        *)
            print_warning "Unsupported distribution. Attempting generic installation..."
            # Try to install using the Microsoft installation script
            wget -q https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
            
            export HOME=`pwd`
            chmod +x dotnet-install.sh
            ./dotnet-install.sh --channel 10.0 || ./dotnet-install.sh --channel 7.0 || ./dotnet-install.sh --channel 6.0
            
            # Add to PATH

            export "PATH=$PATH:`pwd`/.dotnet"
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
            sudo apt-get install -y curl wget unzip --skip-broken
            ;;
        "centos"|"rhel"|"fedora"|"amzn")
            if command -v dnf &> /dev/null; then
                sudo dnf install -y curl wget unzip --skip-broken
            else
                sudo yum install -y curl wget unzip --skip-broken
            fi
            ;;
    esac
}

# Function to build the application
build_application() {
    print_status "Building the .NET Graviton Compatibility Test Application..."
    
    # Check if we're in the right directory
    if [ ! -f "GravitonBridge.sln" ]; then
        print_error "GravitonBridge.sln not found. Please run this script from the project root directory."
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

# Function to create run script
create_run_script() {
    print_status "Creating run script..."
    
    cat > run.sh << 'EOF'
#!/bin/bash

# .NET Graviton Compatibility Test Application Runner Script

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .NET is available
if ! command -v dotnet &> /dev/null; then
    print_error ".NET SDK not found. Please run setup.sh first."
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "GravitonBridge.sln" ]; then
    print_error "GravitonBridge.sln not found. Please run this script from the project root directory."
    exit 1
fi

print_status "Starting .NET Graviton Compatibility Test Application..."
print_status "System Architecture: $(uname -m)"
print_status "Operating System: $(uname -s)"

# Navigate to web project directory
cd src/GravitonBridge.Web

# Check if the application was built
if [ ! -d "bin" ]; then
    print_status "Application not built yet. Building now..."
    cd ../..
    dotnet build --configuration Release
    cd src/GravitonBridge.Web
fi

# Set environment variables
export ASPNETCORE_ENVIRONMENT=Development
export ASPNETCORE_URLS="http://localhost:5000"

print_success "Application starting..."
print_status "Once started, open your browser to: http://localhost:5000"
print_status "Press Ctrl+C to stop the application"
echo ""

# Run the application
dotnet run --configuration Release
EOF

    chmod +x run.sh
    print_success "Run script created successfully!"
}

# Function to create systemd service (optional)
create_systemd_service() {
    print_status "Creating systemd service file (optional)..."
    
    CURRENT_DIR=$(pwd)
    USER_NAME=$(whoami)
    
    cat > compatibility-test.service << EOF
[Unit]
Description=.NET Graviton Compatibility Test Application
After=network.target

[Service]
Type=notify
User=$USER_NAME
WorkingDirectory=$CURRENT_DIR/src/GravitonBridge.Web
ExecStart=/usr/bin/dotnet run --configuration Release
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=compatibility-test
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://localhost:5000

[Install]
WantedBy=multi-user.target
EOF

    print_status "Systemd service file created: compatibility-test.service"
    print_status "To install as a system service, run:"
    print_status "  sudo cp compatibility-test.service /etc/systemd/system/"
    print_status "  sudo systemctl enable compatibility-test"
    print_status "  sudo systemctl start compatibility-test"
}

# Function to display final instructions
show_final_instructions() {
    echo ""
    print_success "Setup completed successfully!"
    echo ""
    print_status "Next steps:"
    echo "  1. Run the application: ./run.sh"
    echo "  2. Open your browser to: http://localhost:5000"
    echo "  3. Use the dashboard to run compatibility tests"
    echo ""
    print_status "For production deployment:"
    echo "  - Review the systemd service file: compatibility-test.service"
    echo "  - Configure firewall rules if needed"
    echo "  - Set up reverse proxy (nginx/apache) for external access"
    echo ""
    print_status "Architecture detected: $(uname -m)"
    print_status "This information will be displayed in the application dashboard"
    echo ""
}

# Main execution
main() {
    echo ""
    print_status "=== .NET Graviton Compatibility Test Application Setup ==="
    echo `pwd`
    echo `ls -al`
    echo ""
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_warning "Running as root. Some operations may require non-root user."
    fi
    
    # Detect distribution
    detect_distro
    
    # Install dependencies
    install_dependencies
    
    # Check if .NET is already installed
    if command -v dotnet &> /dev/null; then
        EXISTING_VERSION=$(dotnet --version)
        print_status ".NET SDK already installed. Version: $EXISTING_VERSION"
        
        # Ask if user wants to reinstall
        read -p "Do you want to reinstall .NET SDK? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_dotnet
        fi
    else
        install_dotnet
    fi
    
    # Verify installation
    if ! verify_dotnet; then
        print_error "Setup failed. Please check the error messages above."
        exit 1
    fi
    
    # Build application
    build_application
    
    # Create run script
    create_run_script
    
    # Create systemd service
    create_systemd_service
    
    # Show final instructions
    show_final_instructions
}

# Run main function
main "$@"
