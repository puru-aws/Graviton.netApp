# CodeDeploy Deployment Guide

This guide explains how to deploy the .NET Graviton Compatibility Test Application using AWS CodeDeploy.

## 📋 Prerequisites

### AWS Setup
1. **EC2 Instance** with CodeDeploy agent installed
2. **IAM Role** for EC2 instance with CodeDeploy permissions
3. **CodeDeploy Application** and Deployment Group configured
4. **S3 Bucket** for deployment artifacts

### EC2 Instance Requirements
- Amazon Linux 2, Ubuntu 18.04+, or CentOS 7+
- CodeDeploy agent installed and running
- Port 5000 open in Security Group
- IAM role attached with necessary permissions

## 🚀 Deployment Process

### 1. Package the Application
```bash
# Create deployment package
zip -r graviton-bridge-deployment.zip . -x "*.git*" "bin/*" "obj/*" "*.zip"
```

### 2. Upload to S3
```bash
aws s3 cp graviton-bridge-deployment.zip s3://your-deployment-bucket/graviton-bridge/
```

### 3. Create CodeDeploy Deployment
```bash
aws deploy create-deployment \
  --application-name GravitonBridge \
  --deployment-group-name production \
  --s3-location bucket=your-deployment-bucket,key=graviton-bridge/graviton-bridge-deployment.zip,bundleType=zip
```

## 📁 Deployment Structure

The application will be deployed to `/opt/graviton-bridge/` with the following structure:

```
/opt/graviton-bridge/
├── src/
│   ├── GravitonBridge.Core/
│   ├── GravitonBridge.Data/
│   ├── GravitonBridge.Services/
│   └── GravitonBridge.Web/
├── scripts/
│   ├── beforeinstall.sh
│   ├── install.sh
│   ├── start.sh
│   ├── stop.sh
│   ├── validate.sh
│   └── run.sh
├── appspec.yml
├── GravitonBridge.sln
└── README.md
```

## 🔄 Deployment Lifecycle

### 1. BeforeInstall (`scripts/beforeinstall.sh`)
- Stops existing application
- Cleans up previous deployment
- Prepares deployment directory

### 2. Install (File Copy)
- Copies application files to `/opt/graviton-bridge/`
- Sets proper permissions

### 3. AfterInstall (`scripts/install.sh`)
- Installs .NET SDK if not present
- Builds the application
- Creates systemd service

### 4. ApplicationStart (`scripts/start.sh`)
- Configures firewall
- Starts the systemd service
- Verifies service startup

### 5. ValidateService (`scripts/validate.sh`)
- Checks service health
- Tests HTTP endpoints
- Validates deployment success

## 🛠️ Manual Operations

### Check Service Status
```bash
sudo systemctl status graviton-bridge
```

### View Logs
```bash
# Real-time logs
journalctl -u graviton-bridge -f

# Recent logs
journalctl -u graviton-bridge --since "10 minutes ago"
```

### Manual Service Control
```bash
# Start service
sudo systemctl start graviton-bridge

# Stop service
sudo systemctl stop graviton-bridge

# Restart service
sudo systemctl restart graviton-bridge

# Enable auto-start
sudo systemctl enable graviton-bridge
```

### Manual Application Run (Development)
```bash
cd /opt/graviton-bridge
./scripts/run.sh
```

## 🔧 Configuration

### Environment Variables
The application runs with these environment variables:
- `ASPNETCORE_ENVIRONMENT=Production`
- `ASPNETCORE_URLS=http://0.0.0.0:5000`
- `ASPNETCORE_FORWARDEDHEADERS_ENABLED=true`

### Systemd Service
Service file location: `/etc/systemd/system/graviton-bridge.service`

### Database
SQLite database is created at: `/opt/graviton-bridge/src/GravitonBridge.Web/compatibility_test.db`

## 🌐 Access

After successful deployment:
- **Local**: http://localhost:5000
- **Network**: http://EC2_PUBLIC_IP:5000
- **Health Check**: http://EC2_PUBLIC_IP:5000/health

## 🐛 Troubleshooting

### Deployment Fails
1. Check CodeDeploy logs: `/var/log/aws/codedeploy-agent/`
2. Verify IAM permissions
3. Check script execution logs

### Application Won't Start
1. Check systemd logs: `journalctl -u graviton-bridge`
2. Verify .NET SDK installation: `dotnet --version`
3. Check port availability: `netstat -tlnp | grep :5000`

### Build Errors
1. Check if all dependencies are installed
2. Verify project files are complete
3. Run manual build: `cd /opt/graviton-bridge && dotnet build`

### Network Access Issues
1. Verify Security Group allows port 5000
2. Check local firewall: `sudo ufw status` or `firewall-cmd --list-ports`
3. Test local connectivity: `curl http://localhost:5000`

## 📊 Monitoring

### Health Checks
- Application health: `curl http://localhost:5000/health`
- Service status: `systemctl is-active graviton-bridge`
- Port listening: `netstat -tlnp | grep :5000`

### Performance Monitoring
The application includes built-in system monitoring and benchmarking tools accessible through the web interface.

## 🔒 Security

### Firewall Configuration
```bash
# Ubuntu/Debian
sudo ufw allow 5000

# CentOS/RHEL/Amazon Linux
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload
```

### Security Headers
The application includes basic security headers:
- X-Content-Type-Options: nosniff
- X-Frame-Options: DENY
- X-XSS-Protection: 1; mode=block

## 📞 Support

For deployment issues:
1. Check this troubleshooting guide
2. Review CodeDeploy logs
3. Verify EC2 instance configuration
4. Test manual deployment steps

---

**Quick Commands Reference:**
```bash
# Check deployment status
aws deploy get-deployment --deployment-id <deployment-id>

# View service status
sudo systemctl status graviton-bridge

# View application logs
journalctl -u graviton-bridge -f

# Test application
curl -I http://localhost:5000
```