# .NET Graviton Compatibility Test Application

A comprehensive .NET web application designed to test and monitor compatibility between different system architectures, specifically x86 and ARM64 (Graviton) based instances.

## 🎯 Purpose

This application helps developers and system administrators verify that .NET applications work consistently across different architectures by:
- Detecting system architecture and runtime information
- Running performance benchmarks to compare CPU, memory, and I/O operations
- Providing a web dashboard to monitor compatibility status
- Storing benchmark results for historical comparison

## 🏗️ Architecture

The application follows a clean, layered architecture:

```
GravitonBridge/
├── src/
│   ├── GravitonBridge.Core/     # Domain models and entities
│   │   └── Models/                    # SystemInfo, BenchmarkResult, TaskItem
│   ├── GravitonBridge.Data/     # Data access layer
│   │   └── ApplicationDbContext.cs    # Entity Framework configuration
│   ├── GravitonBridge.Services/ # Business logic
│   │   ├── SystemInfoService.cs       # System information detection
│   │   └── BenchmarkService.cs        # Performance benchmarking
│   └── GravitonBridge.Web/      # Web application
│       ├── Controllers/               # MVC controllers
│       ├── Views/                     # Razor views
│       ├── Hubs/                      # SignalR hubs for real-time updates
│       └── wwwroot/                   # Static files (CSS, JS)
├── README.md
├── setup.sh                          # Automated setup script
└── run.sh                            # Application runner script
```

## 🚀 Features

### System Information Detection
- **Architecture Detection**: Automatically identifies x86, x64, or ARM64 architecture
- **Runtime Information**: Displays .NET version, OS details, and system specifications
- **Real-time Monitoring**: Live updates of system metrics

### Performance Benchmarking
- **CPU Benchmark**: Prime number calculations to test computational performance
- **Memory Benchmark**: Large array operations and memory management tests
- **File I/O Benchmark**: File creation, reading, and manipulation performance
- **Cross-Architecture Comparison**: Compare performance between different architectures

### Web Dashboard
- **Responsive Interface**: Clean, modern web interface accessible from any browser
- **Real-time Updates**: SignalR integration for live benchmark results
- **Historical Data**: View and compare past benchmark results
- **Architecture-Specific Visualization**: Color-coded results based on system architecture

### Data Persistence
- **SQLite Database**: Lightweight, cross-platform database for storing results
- **Entity Framework Core**: Modern ORM for data access
- **Automatic Schema Management**: Database created and updated automatically

## 🛠️ Technology Stack

- **.NET 10** (Preview) - Latest .NET framework
- **ASP.NET Core MVC** - Web framework
- **Entity Framework Core** - Object-relational mapping
- **SQLite** - Embedded database
- **SignalR** - Real-time web functionality
- **Bootstrap** - Responsive CSS framework
- **Chart.js** - Data visualization (planned)

## 📋 Prerequisites

- **.NET 10 SDK** (or compatible version)
- **Linux-based operating system** (Ubuntu, CentOS, Amazon Linux, etc.)
- **Bash shell** (for setup scripts)
- **Internet connection** (for package downloads)

## 🔧 Installation & Setup

### Option 1: Automated Setup (Recommended)

1. **Download the setup script**:
   ```bash
   curl -O https://your-repo/setup.sh
   chmod +x setup.sh
   ```

2. **Run the setup script**:
   ```bash
   ./setup.sh
   ```

3. **Start the application**:
   ```bash
   ./run.sh
   ```

### Option 2: Manual Setup

See the [Manual Setup Guide](#manual-setup-guide) section below.

## 🏃‍♂️ Quick Start

1. **Clone or download** the application files
2. **Run the setup script**: `./setup.sh`
3. **Start the application**: `./run.sh`
4. **Open your browser** to `http://localhost:5000` (or the displayed URL)
5. **Run benchmarks** using the dashboard interface

## 📊 Using the Application

### Dashboard Overview
- **System Information Panel**: Shows current system architecture, OS, and runtime details
- **Performance Metrics**: Displays CPU cores, memory usage, and system status
- **Benchmark Controls**: Buttons to run different types of performance tests

### Running Benchmarks
1. **CPU Test**: Click "Run CPU Test" to start computational benchmark
2. **Memory Test**: Click "Run Memory Test" to test memory operations
3. **File I/O Test**: Click "Run File I/O Test" to benchmark disk operations
4. **View Results**: Results appear in real-time and are stored for comparison

### Comparing Architectures
1. **Deploy on x86 instance**: Note the architecture detection and benchmark results
2. **Deploy on ARM64/Graviton instance**: Compare the results
3. **Analyze differences**: Use the dashboard to identify any compatibility issues

## 🔍 Graviton Compatibility Testing Workflow

### For x86 to ARM64 Migration Testing:

1. **Baseline Testing**:
   - Deploy application on current x86 infrastructure
   - Run comprehensive benchmarks
   - Document performance metrics

2. **Target Testing**:
   - Deploy same application on ARM64/Graviton instances
   - Run identical benchmarks
   - Compare results with baseline

3. **Analysis**:
   - Review performance differences
   - Identify any functional issues
   - Validate application behavior consistency

## 📁 Project Structure Details

### Core Models
- **SystemInfo**: System architecture and runtime information
- **BenchmarkResult**: Performance test results with metrics
- **TaskItem**: Task management for tracking tests

### Services
- **SystemInfoService**: Detects and provides system information
- **BenchmarkService**: Executes performance tests and collects metrics

### Web Components
- **HomeController**: Main dashboard controller
- **SystemMonitorHub**: SignalR hub for real-time updates
- **Views**: Razor templates for web interface

## 🐛 Troubleshooting

### Common Issues

**Port Already in Use**:
```bash
# Check what's using the port
sudo netstat -tlnp | grep :5000
# Kill the process or use a different port
```

**Permission Denied**:
```bash
# Make scripts executable
chmod +x setup.sh run.sh
```

**Missing .NET SDK**:
```bash
# The setup script will install .NET, but you can also install manually
wget https://dot.net/v1/dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --version latest
```

### Logs and Debugging
- Application logs are displayed in the terminal when running
- Database file: `compatibility_test.db` (created automatically)
- Check browser console for client-side errors

## 🔒 Security Considerations

- **Development Mode**: Application runs in development mode by default
- **Database**: SQLite database is created locally (no external connections)
- **Network**: Application binds to localhost by default
- **Production Deployment**: Configure HTTPS and proper security headers for production

## 🚀 Deployment Options

### Local Development
```bash
./run.sh
```

### Systemd Service (Linux)
```bash
# Create service file
sudo nano /etc/systemd/system/compatibility-test.service

# Enable and start service
sudo systemctl enable compatibility-test
sudo systemctl start compatibility-test
```

### Docker Container
```bash
# Build container
docker build -t compatibility-test .

# Run container
docker run -p 5000:5000 compatibility-test
```

### Cloud Deployment
- **AWS EC2**: Deploy on both x86 and Graviton instances
- **Azure VMs**: Test on different VM sizes and architectures
- **Google Cloud**: Compare performance across machine types

## 📈 Performance Metrics

The application measures:
- **Execution Time**: How long operations take to complete
- **Memory Usage**: RAM consumption during tests
- **Operations per Second**: Throughput measurements
- **Architecture-Specific Metrics**: ARM64 vs x86 performance characteristics

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on both x86 and ARM64 if possible
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For issues and questions:
- Check the troubleshooting section
- Review application logs
- Create an issue in the repository

---

## Manual Setup Guide

### Step 1: Install .NET SDK

**Ubuntu/Debian**:
```bash
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y dotnet-sdk-8.0
```

**CentOS/RHEL/Amazon Linux**:
```bash
sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm
sudo yum install -y dotnet-sdk-8.0
```

### Step 2: Verify Installation
```bash
dotnet --version
```

### Step 3: Build Application
```bash
# Navigate to project directory
cd /path/to/GravitonBridge

# Restore dependencies
dotnet restore

# Build the solution
dotnet build

# Run the application
cd src/GravitonBridge.Web
dotnet run
```

### Step 4: Access Application
Open your browser to `http://localhost:5000` or the URL shown in the terminal.

---

*This application is designed to help ensure your .NET applications work seamlessly across different architectures, making your migration to ARM64/Graviton instances smooth and confident.*
