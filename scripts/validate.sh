#!/bin/bash
set -e

# CodeDeploy ValidateService Hook
# This script validates that the application is running correctly

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

print_status "=== CodeDeploy ValidateService Hook ==="

# Wait for application to fully start
print_status "Waiting for application to start..."
sleep 10

# Check if systemd service is running
print_status "Checking systemd service status..."
if systemctl is-active --quiet graviton-bridge; then
    print_success "Graviton Bridge service is running"
else
    print_error "Graviton Bridge service is not running"
    print_status "Service status:"
    systemctl status graviton-bridge --no-pager -l || true
    print_status "Recent logs:"
    journalctl -u graviton-bridge --no-pager -l --since "2 minutes ago" || true
    exit 1
fi

# Check if port 5000 is listening
print_status "Checking if port 5000 is listening..."
if command -v netstat &> /dev/null; then
    if netstat -tlnp | grep -q ":5000 "; then
        print_success "Port 5000 is listening"
    else
        print_error "Port 5000 is not listening"
        netstat -tlnp | grep ":5000" || true
        exit 1
    fi
elif command -v ss &> /dev/null; then
    if ss -tlnp | grep -q ":5000 "; then
        print_success "Port 5000 is listening"
    else
        print_error "Port 5000 is not listening"
        ss -tlnp | grep ":5000" || true
        exit 1
    fi
else
    print_warning "Neither netstat nor ss available, skipping port check"
fi

# Test HTTP endpoint
print_status "Testing HTTP endpoint..."
max_attempts=5
attempt=1

while [ $attempt -le $max_attempts ]; do
    print_status "Attempt $attempt/$max_attempts: Testing http://localhost:5000"
    
    if curl -f -s -o /dev/null --max-time 10 http://localhost:5000; then
        print_success "HTTP endpoint is responding"
        break
    else
        if [ $attempt -eq $max_attempts ]; then
            print_error "HTTP endpoint is not responding after $max_attempts attempts"
            print_status "Curl verbose output:"
            curl -v --max-time 10 http://localhost:5000 || true
            print_status "Service logs:"
            journalctl -u graviton-bridge --no-pager -l --since "2 minutes ago" || true
            exit 1
        else
            print_status "Attempt failed, waiting 5 seconds before retry..."
            sleep 5
        fi
    fi
    
    ((attempt++))
done

# Test health endpoint if available
print_status "Testing health endpoint..."
if curl -f -s -o /dev/null --max-time 10 http://localhost:5000/health; then
    print_success "Health endpoint is responding"
else
    print_warning "Health endpoint not responding (this may be normal)"
fi

# Display final status
print_status "Final validation results:"
echo "  - Service Status: $(systemctl is-active graviton-bridge)"
echo "  - Port 5000: Listening"
echo "  - HTTP Endpoint: Responding"

# Get public IP for external access info
if command -v curl &> /dev/null; then
    PUBLIC_IP=$(curl -s --max-time 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "unknown")
    if [ "$PUBLIC_IP" != "unknown" ]; then
        print_success "Application is accessible at: http://$PUBLIC_IP:5000"
    fi
fi

print_success "ValidateService completed successfully - Application is running and healthy!"