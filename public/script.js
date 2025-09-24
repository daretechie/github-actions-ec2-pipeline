class AppMonitor {
  constructor() {
    this.loadAllData();
    // Refresh data every 30 seconds
    setInterval(() => this.loadAllData(), 30000);
  }

  async loadAllData() {
    await Promise.all([
      this.loadHealthStatus(),
      this.loadAppInfo(),
      this.loadServerStatus(),
    ]);
  }

  async loadHealthStatus() {
    try {
      const response = await fetch("/api/health");
      const data = await response.json();
      document.getElementById("health-status").innerHTML = `
                <div class="status-healthy">● ${data.status.toUpperCase()}</div>
                <div><strong>Version:</strong> ${data.version}</div>
                <div><strong>Environment:</strong> ${data.environment}</div>
                <div><strong>Uptime:</strong> ${this.formatUptime(
                  data.uptime
                )}</div>
                <div><strong>Last Check:</strong> ${new Date(
                  data.timestamp
                ).toLocaleString()}</div>
            `;
    } catch (error) {
      document.getElementById("health-status").innerHTML =
        '<div class="status-error">● CONNECTION ERROR</div><div>Unable to connect to server API</div>';
    }
  }

  async loadAppInfo() {
    try {
      const response = await fetch("/api/info");
      const data = await response.json();
      document.getElementById("app-info").innerHTML = `
                <div><strong>Name:</strong> ${data.name}</div>
                <div><strong>Description:</strong> ${data.description}</div>
                <div><strong>Environment:</strong> ${data.environment}</div>
                <div><strong>Server:</strong> ${data.server}</div>
                <div><strong>Deployed:</strong> ${new Date(
                  data.deployment_time
                ).toLocaleString()}</div>
            `;
    } catch (error) {
      document.getElementById("app-info").innerHTML =
        '<div class="status-error">Unable to load application info</div>';
    }
  }

  async loadServerStatus() {
    try {
      const response = await fetch("/api/status");
      const data = await response.json();
      document.getElementById("server-status").innerHTML = `
                <div><strong>Platform:</strong> ${data.platform}</div>
                <div><strong>Node.js:</strong> ${data.node_version}</div>
                <div><strong>Memory Used:</strong> ${this.formatBytes(
                  data.memory_usage.heapUsed
                )}</div>
                <div><strong>Memory Total:</strong> ${this.formatBytes(
                  data.memory_usage.heapTotal
                )}</div>
                <div><strong>External Memory:</strong> ${this.formatBytes(
                  data.memory_usage.external
                )}</div>
            `;
    } catch (error) {
      document.getElementById("server-status").innerHTML =
        '<div class="status-error">Unable to load server status</div>';
    }
  }

  formatUptime(seconds) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    return `${hours}h ${minutes}m ${secs}s`;
  }

  formatBytes(bytes) {
    if (bytes === 0) return "0 Bytes";
    const k = 1024;
    const sizes = ["Bytes", "KB", "MB", "GB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
  }
}

// Initialize the monitor when page loads
document.addEventListener("DOMContentLoaded", () => {
  new AppMonitor();
});
