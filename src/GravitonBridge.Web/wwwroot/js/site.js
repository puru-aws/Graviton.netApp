// Site-wide JavaScript functionality

// Utility functions
function formatBytes(bytes, decimals = 2) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

function formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function showToast(message, type = 'info') {
    // Simple toast notification
    const toast = document.createElement('div');
    toast.className = `alert alert-${type} alert-dismissible fade show position-fixed`;
    toast.style.top = '20px';
    toast.style.right = '20px';
    toast.style.zIndex = '9999';
    toast.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    document.body.appendChild(toast);
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
        if (toast.parentNode) {
            toast.parentNode.removeChild(toast);
        }
    }, 5000);
}

// Initialize tooltips if Bootstrap is available
document.addEventListener('DOMContentLoaded', function() {
    if (typeof bootstrap !== 'undefined') {
        var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
        var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
            return new bootstrap.Tooltip(tooltipTriggerEl);
        });
    }
});

// Global error handler
window.addEventListener('error', function(e) {
    console.error('Global error:', e.error);
});

// SignalR connection helper
class SignalRHelper {
    constructor(hubUrl) {
        this.hubUrl = hubUrl;
        this.connection = null;
        this.isConnected = false;
    }

    async connect() {
        if (typeof signalR === 'undefined') {
            console.error('SignalR library not loaded');
            return false;
        }

        this.connection = new signalR.HubConnectionBuilder()
            .withUrl(this.hubUrl)
            .withAutomaticReconnect()
            .build();

        try {
            await this.connection.start();
            this.isConnected = true;
            console.log('SignalR connected to', this.hubUrl);
            return true;
        } catch (err) {
            console.error('SignalR connection error:', err);
            this.isConnected = false;
            return false;
        }
    }

    async disconnect() {
        if (this.connection) {
            await this.connection.stop();
            this.isConnected = false;
        }
    }

    on(methodName, callback) {
        if (this.connection) {
            this.connection.on(methodName, callback);
        }
    }

    async invoke(methodName, ...args) {
        if (this.connection && this.isConnected) {
            try {
                return await this.connection.invoke(methodName, ...args);
            } catch (err) {
                console.error(`Error invoking ${methodName}:`, err);
                throw err;
            }
        } else {
            throw new Error('SignalR connection not established');
        }
    }
}

// Make SignalRHelper available globally
window.SignalRHelper = SignalRHelper;
