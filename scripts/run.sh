#!/bin/bash

# .NET Graviton Compatibility Test Application Runner Script
# This script is for manual testing - CodeDeploy uses systemd service

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

# Check if .NET is available
if ! command -v dotnet &> /dev/null; then
    print_error ".NET SDK not found. Please run setup.sh first."
    exit 1
fi

# Determine working directory (support both local dev and deployed)
if [ -f "GravitonBridge.sln" ]; then
    WORK_DIR="."
elif [ -f "/opt/graviton-bridge/GravitonBridge.sln" ]; then
    WORK_DIR="/opt/graviton-bridge"
    cd "$WORK_DIR"
else
    print_error "GravitonBridge.sln not found. Please run this script from the project root directory or ensure the application is deployed."
    exit 1
fi

print_status "Starting .NET Graviton Compatibility Test Application..."
print_status "Working Directory: $(pwd)"
print_status "System Architecture: $(uname -m)"
print_status "Operating System: $(uname -s)"

# Check if systemd service exists and is running
if systemctl list-unit-files | grep -q graviton-bridge.service; then
    if systemctl is-active --quiet graviton-bridge; then
        print_warning "Graviton Bridge service is already running via systemd"
        print_status "To stop the service: sudo systemctl stop graviton-bridge"
        print_status "To view logs: journalctl -u graviton-bridge -f"
        print_status "Service status:"
        systemctl status graviton-bridge --no-pager -l
        exit 0
    fi
fi

# Navigate to web project directory
cd src/GravitonBridge.Web

# Check if the application was built
if [ ! -d "bin" ]; then
    print_status "Application not built yet. Building now..."
    cd ../..
    dotnet build --configuration Release
    cd src/GravitonBridge.Web
fi

# Set environment variables for production-like deployment
export ASPNETCORE_ENVIRONMENT=Production
export ASPNETCORE_URLS="http://0.0.0.0:5000"
export ASPNETCORE_FORWARDEDHEADERS_ENABLED=true

print_success "Application starting..."
print_status "Local URL: http://localhost:5000"
print_status "Network URL: http://0.0.0.0:5000"

# Get public IP if available
if command -v curl &> /dev/null; then
    PUBLIC_IP=$(curl -s --max-time 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "")
    if [ -n "$PUBLIC_IP" ]; then
        print_status "Public URL: http://$PUBLIC_IP:5000"
    fi
fi

print_status "Press Ctrl+C to stop the application"
echo ""

# Run the application
dotnet run --configuration Release
