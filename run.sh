#!/bin/bash

# .NET Graviton Compatibility Test Application Runner Script

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if .NET is available
    if ! command -v dotnet &> /dev/null; then
        print_error ".NET SDK not found. Please install .NET SDK or run setup.sh first."
        print_status "To install .NET SDK manually:"
        print_status "  Ubuntu/Debian: sudo apt-get install dotnet-sdk-8.0"
        print_status "  CentOS/RHEL: sudo yum install dotnet-sdk-8.0"
        print_status "  Or run: ./setup.sh"
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "GravitonBridge.sln" ]; then
        print_error "GravitonBridge.sln not found."
        print_error "Please run this script from the project root directory."
        exit 1
    fi
    
    print_success "Prerequisites check passed!"
}

# Function to display system information
show_system_info() {
    print_status "System Information:"
    echo "  Architecture: $(uname -m)"
    echo "  Operating System: $(uname -s) $(uname -r)"
    echo "  .NET Version: $(dotnet --version)"
    echo "  Current Directory: $(pwd)"
    echo ""
}

# Function to build application if needed
ensure_built() {
    if [ ! -d "src/GravitonBridge.Web/bin" ] || [ "$1" = "--rebuild" ]; then
        print_status "Building application..."
        
        # Restore NuGet packages
        print_status "Restoring NuGet packages..."
        dotnet restore
        
        # Build the solution
        print_status "Building the solution..."
        dotnet build --configuration Release
        
        if [ $? -eq 0 ]; then
            print_success "Application built successfully!"
        else
            print_error "Build failed. Please check the error messages above."
            exit 1
        fi
    else
        print_status "Application already built. Use --rebuild to force rebuild."
    fi
}

# Function to start the application
start_application() {
    print_status "Starting .NET Graviton Compatibility Test Application..."
    
    # Navigate to web project directory
    cd src/GravitonBridge.Web
    
    # Set environment variables for internet deployment
    export ASPNETCORE_ENVIRONMENT=Production
    export ASPNETCORE_URLS="http://0.0.0.0:5000"
    export ASPNETCORE_FORWARDEDHEADERS_ENABLED=true
    
    # Display startup information
    echo ""
    print_success "Application starting..."
    print_status "HTTP URL: http://localhost:5000;http://0.0.0.0:5000"
    print_status "HTTPS URL: https://localhost:5001"
    if command -v hostname &> /dev/null && hostname -I &> /dev/null; then
        print_status "Network URL: http://$(hostname -I | awk '{print $1}'):5000"
    else
        print_status "Network URL: http://$(hostname):5000"
    fi
    print_status "Press Ctrl+C to stop the application"
    echo ""
    print_warning "Note: If running on a remote server, ensure port 5000 is open in firewall"
    echo ""
    
    # Run the application
    dotnet run --configuration Release --urls "http://0.0.0.0:5000"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --rebuild      Force rebuild the application"
    echo "  --info         Show system information only"
    echo "  --check        Check prerequisites only"
    echo ""
    echo "Examples:"
    echo "  $0              # Start the application"
    echo "  $0 --rebuild    # Rebuild and start the application"
    echo "  $0 --info       # Show system information"
    echo "  $0 --check      # Check if prerequisites are met"
    echo ""
}

# Function to handle cleanup on exit
cleanup() {
    echo ""
    print_status "Shutting down application..."
    print_success "Application stopped."
}

# Set up signal handlers
trap cleanup EXIT INT TERM

# Main execution
main() {
    case "$1" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --info)
            show_system_info
            exit 0
            ;;
        --check)
            check_prerequisites
            exit 0
            ;;
        --rebuild)
            check_prerequisites
            show_system_info
            ensure_built --rebuild
            start_application
            ;;
        "")
            check_prerequisites
            show_system_info
            ensure_built
            start_application
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
