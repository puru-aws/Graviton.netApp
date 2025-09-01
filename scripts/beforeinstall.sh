#!/bin/bash
set -e

# CodeDeploy BeforeInstall Hook
# This script prepares the system for deployment

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

print_status "=== CodeDeploy BeforeInstall Hook ==="

# Stop any existing application
print_status "Stopping existing application if running..."
if systemctl is-active --quiet graviton-bridge 2>/dev/null; then
    systemctl stop graviton-bridge
    print_status "Stopped existing graviton-bridge service"
fi

# Kill any dotnet processes running on port 5000
print_status "Checking for processes on port 5000..."
if lsof -ti:5000 >/dev/null 2>&1; then
    print_status "Killing processes on port 5000..."
    lsof -ti:5000 | xargs kill -9 2>/dev/null || true
fi

# Create application directory
print_status "Creating application directory..."
mkdir -p /opt/graviton-bridge
chown -R ec2-user:ec2-user /opt/graviton-bridge
chmod 755 /opt/graviton-bridge

# Clean up old deployment if exists
if [ -d "/opt/graviton-bridge/src" ]; then
    print_status "Cleaning up previous deployment..."
    rm -rf /opt/graviton-bridge/src
    rm -rf /opt/graviton-bridge/scripts
    rm -f /opt/graviton-bridge/*.sln
    rm -f /opt/graviton-bridge/*.md
    rm -f /opt/graviton-bridge/*.sh
fi

print_success "BeforeInstall completed successfully"