#!/bin/bash
set -e

# CodeDeploy ApplicationStart Hook
# This script starts the .NET application

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

print_status "=== CodeDeploy ApplicationStart Hook ==="

# Change to application directory
cd /opt/graviton-bridge

# Open firewall port
print_status "Configuring firewall..."
if command -v ufw &> /dev/null; then
    # Ubuntu/Debian
    sudo ufw allow 5000 2>/dev/null || true
elif command -v firewall-cmd &> /dev/null; then
    # CentOS/RHEL/Amazon Linux
    sudo firewall-cmd --permanent --add-port=5000/tcp 2>/dev/null || true
    sudo firewall-cmd --reload 2>/dev/null || true
fi

# Start the application using systemd
print_status "Starting graviton-bridge service..."
sudo systemctl start graviton-bridge

# Wait a moment for the service to start
sleep 5

# Check if service is running
if systemctl is-active --quiet graviton-bridge; then
    print_success "Graviton Bridge application started successfully"
    print_status "Service status:"
    systemctl status graviton-bridge --no-pager -l
else
    print_error "Failed to start graviton-bridge service"
    print_status "Service logs:"
    journalctl -u graviton-bridge --no-pager -l --since "1 minute ago"
    exit 1
fi

print_status "Application should be accessible at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5000"
print_success "ApplicationStart completed successfully"