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
sleep 15

# Check if the application process is actually running
print_status "Checking for dotnet processes..."
if pgrep -f "dotnet.*GravitonBridge" >/dev/null; then
    print_success "Dotnet application process is running"
    print_status "Process details:"
    ps aux | grep -E "dotnet.*GravitonBridge|PID" | head -5
else
    print_warning "No dotnet GravitonBridge process found"
    print_status "All dotnet processes:"
    ps aux | grep dotnet || print_status "No dotnet processes found"
fi

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

# Enhanced diagnostics before port check
print_status "Enhanced diagnostics..."
print_status "Service detailed status:"
systemctl status graviton-bridge --no-pager -l || true
print_status "Recent application logs:"
journalctl -u graviton-bridge --no-pager -l --since "3 minutes ago" || true

# Check if port 5000 is listening
print_status "Checking if port 5000 is listening..."
PORT_LISTENING=false

if command -v ss &> /dev/null; then
    print_status "Using ss to check port 5000..."
    if sudo ss -tlnp | grep -q ":5000 "; then
        print_success "Port 5000 is listening (ss)"
        PORT_LISTENING=true
        sudo ss -tlnp | grep ":5000" || true
    else
        print_status "Port 5000 not found with ss, checking all listening ports:"
        sudo ss -tlnp | head -10 || true
    fi
elif command -v netstat &> /dev/null; then
    print_status "Using netstat to check port 5000..."
    if sudo netstat -tlnp | grep -q ":5000 "; then
        print_success "Port 5000 is listening (netstat)"
        PORT_LISTENING=true
        sudo netstat -tlnp | grep ":5000" || true
    else
        print_status "Port 5000 not found with netstat, checking all listening ports:"
        sudo netstat -tlnp | head -10 || true
    fi
else
    print_warning "Neither netstat nor ss available, trying lsof..."
    if command -v lsof &> /dev/null; then
        if sudo lsof -i :5000 >/dev/null 2>&1; then
            print_success "Port 5000 is listening (lsof)"
            PORT_LISTENING=true
            sudo lsof -i :5000 || true
        else
            print_status "Port 5000 not found with lsof"
        fi
    fi
fi

if [ "$PORT_LISTENING" = false ]; then
    print_error "Port 5000 is not listening"
    print_status "Checking what ports are being used by dotnet processes..."
    sudo lsof -i -P -n | grep dotnet || print_status "No dotnet processes found with open ports"
    print_status "Checking application configuration..."
    print_status "Environment variables in service:"
    sudo systemctl show graviton-bridge --property=Environment || true
    print_status "Application logs (last 50 lines):"
    journalctl -u graviton-bridge --no-pager -l -n 50 || true
    exit 1
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