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
