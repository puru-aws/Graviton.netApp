#!/bin/bash
set -e

# CodeDeploy ApplicationStop Hook
# This script stops the .NET application

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

print_status "=== CodeDeploy ApplicationStop Hook ==="

# Stop the systemd service if it exists and is running
if systemctl list-unit-files | grep -q graviton-bridge.service; then
    if systemctl is-active --quiet graviton-bridge; then
        print_status "Stopping graviton-bridge service..."
        sudo systemctl stop graviton-bridge
        
        # Wait for graceful shutdown
        sleep 3
        
        if systemctl is-active --quiet graviton-bridge; then
            print_error "Service did not stop gracefully, forcing stop..."
            sudo systemctl kill graviton-bridge
            sleep 2
        fi
        
        print_success "Graviton Bridge service stopped"
    else
        print_status "Graviton Bridge service is not running"
    fi
else
    print_status "Graviton Bridge service not found"
fi

# Kill any remaining dotnet processes on port 5000
print_status "Checking for processes on port 5000..."
if command -v lsof &> /dev/null && lsof -ti:5000 >/dev/null 2>&1; then
    print_status "Killing remaining processes on port 5000..."
    lsof -ti:5000 | xargs kill -9 2>/dev/null || true
    sleep 1
fi

print_success "ApplicationStop completed successfully"