const express = require("express");
const path = require("path");

const app = express();

// Serve static files
app.use(express.static(path.join(__dirname, "../public")));

// API endpoints
app.get("/api/health", (req, res) => {
  res.json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version || "1.0.0",
  });
});

app.get("/api/info", (req, res) => {
  res.json({
    name: "GitHub Actions Pipeline Demo",
    description: "A sample app demonstrating CI/CD with GitHub Actions",
    environment: process.env.NODE_ENV || "development",
  });
});

module.exports = app;
