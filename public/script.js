async function loadStatus() {
  try {
    const response = await fetch("/api/health");
    const data = await response.json();
    document.getElementById("status").innerHTML = `
            <div class="status-healthy">Status: ${data.status}</div>
            <div>Version: ${data.version}</div>
            <div>Last Updated: ${data.timestamp}</div>
        `;
  } catch (error) {
    document.getElementById("status").innerHTML =
      '<div class="status-loading">Unable to connect to API</div>';
  }
}

async function loadInfo() {
  try {
    const response = await fetch("/api/info");
    const data = await response.json();
    document.getElementById("info").innerHTML = `
            <div><strong>Name:</strong> ${data.name}</div>
            <div><strong>Description:</strong> ${data.description}</div>
            <div><strong>Environment:</strong> ${data.environment}</div>
        `;
  } catch (error) {
    document.getElementById("info").innerHTML =
      '<div class="status-loading">Unable to load application info</div>';
  }
}

// Load data when page loads
document.addEventListener("DOMContentLoaded", () => {
  loadStatus();
  loadInfo();
});
