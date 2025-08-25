# Quick Deployment Guide

This guide provides step-by-step instructions for deploying the .NET Graviton Compatibility Test Application on Linux systems.

## 🚀 Quick Start (3 Steps)

### Step 1: Download/Copy the Application
```bash
# If using git
git clone <repository-url>
cd GravitonBridge

# Or if you have the files locally, ensure you're in the project root directory
# (where GravitonBridge.sln is located)
```

### Step 2: Run Setup Script
```bash
./setup.sh
```

### Step 3: Start the Application
```bash
./run.sh
```

That's it! Open your browser to `http://localhost:5000`

## 📋 Manual Installation (Alternative)

If the automated setup doesn't work for your system:

### Ubuntu/Debian Systems
```bash
# Install .NET SDK
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y dotnet-sdk-8.0

# Build and run
dotnet restore
dotnet build
cd src/GravitonBridge.Web
dotnet run
```

### CentOS/RHEL/Amazon Linux
```bash
# Install .NET SDK
sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm
sudo yum install -y dotnet-sdk-8.0

# Build and run
dotnet restore
dotnet build
cd src/GravitonBridge.Web
dotnet run
```

## 🔧 Script Options

### Setup Script (`setup.sh`)
- Automatically detects your Linux distribution
- Installs .NET SDK if not present
- Builds the application
- Creates run script and systemd service file

### Run Script (`run.sh`)
```bash
./run.sh              # Start the application
./run.sh --rebuild     # Force rebuild and start
./run.sh --info        # Show system information
./run.sh --check       # Check prerequisites
./run.sh --help        # Show help
```

## 🌐 Network Access

### Local Access Only
Default configuration - accessible only from the same machine:
- URL: `http://localhost:5000`

### Network Access (Remote Servers)
To allow access from other machines:

1. **Update the run script** or set environment variable:
   ```bash
   export ASPNETCORE_URLS="http://0.0.0.0:5000"
   ./run.sh
   ```

2. **Configure firewall** (if needed):
   ```bash
   # Ubuntu/Debian
   sudo ufw allow 5000
   
   # CentOS/RHEL
   sudo firewall-cmd --permanent --add-port=5000/tcp
   sudo firewall-cmd --reload
   ```

3. **Access from browser**:
   - URL: `http://YOUR_SERVER_IP:5000`

## 🔄 Production Deployment

### As a System Service
The setup script creates a systemd service file. To use it:

```bash
# Install the service
sudo cp compatibility-test.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable compatibility-test
sudo systemctl start compatibility-test

# Check status
sudo systemctl status compatibility-test

# View logs
sudo journalctl -u compatibility-test -f
```

### With Reverse Proxy (Nginx)
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 🏗️ Architecture Testing Workflow

### Testing x86 to ARM64 Graviton Compatibility

1. **Deploy on x86 Instance**:
   ```bash
   # On x86 Linux instance
   ./setup.sh
   ./run.sh
   # Note the architecture shown in dashboard (x86_64)
   # Run benchmarks and record results
   ```

2. **Deploy on ARM64/Graviton Instance**:
   ```bash
   # On ARM64 Linux instance (AWS Graviton, etc.)
   ./setup.sh
   ./run.sh
   # Note the architecture shown in dashboard (aarch64/arm64)
   # Run same benchmarks
   ```

3. **Compare Results**:
   - Architecture detection should show different values
   - Performance benchmarks can be compared
   - Application functionality should be identical

## 🐛 Troubleshooting

### Common Issues

**"Permission denied" when running scripts**:
```bash
chmod +x setup.sh run.sh
```

**Port 5000 already in use**:
```bash
# Find what's using the port
sudo netstat -tlnp | grep :5000
# Kill the process or change port in run.sh
```

**"dotnet command not found"**:
```bash
# Check if .NET is in PATH
echo $PATH
# If installed via script, reload bash
source ~/.bashrc
```

**Build errors**:
```bash
# Clean and rebuild
dotnet clean
dotnet restore
dotnet build
```

### Logs and Debugging
- Application logs appear in terminal when running
- Database file: `compatibility_test.db` (created automatically)
- For systemd service: `sudo journalctl -u compatibility-test`

## 📊 Using the Application

1. **Open Dashboard**: Navigate to `http://localhost:5000`
2. **View System Info**: Check detected architecture and system details
3. **Run Benchmarks**: Use the buttons to run CPU, Memory, and File I/O tests
4. **Compare Results**: Deploy on different architectures and compare

## 🔒 Security Notes

- Application runs in development mode by default
- Database is local SQLite (no external connections)
- For production: configure HTTPS, authentication, and proper security headers
- Firewall: Only open port 5000 if network access is needed

## 📞 Support

If you encounter issues:
1. Check this troubleshooting guide
2. Review the main README.md
3. Check application logs
4. Verify prerequisites with `./run.sh --check`

---

**Quick Reference Commands:**
```bash
./setup.sh           # One-time setup
./run.sh             # Start application
./run.sh --help      # Show options
./run.sh --info      # System information
