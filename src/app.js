const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const path = require("path");

const app = express();

// Security middleware
app.use(helmet());
app.use(cors());
app.use(morgan("combined"));

// Body parsing middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files
app.use(express.static(path.join(__dirname, "../public")));

// Health check endpoint
app.get("/api/health", (req, res) => {
  res.json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version || "1.0.0",
    environment: process.env.NODE_ENV || "development",
    uptime: process.uptime(),
  });
});

// Application info endpoint
app.get("/api/info", (req, res) => {
  res.json({
    name: "GitHub Actions EC2 Pipeline Demo",
    description: "A Node.js app demonstrating CI/CD with EC2 deployment",
    environment: process.env.NODE_ENV || "development",
    server: process.env.SERVER_NAME || "localhost",
    deployment_time: process.env.DEPLOYMENT_TIME || new Date().toISOString(),
  });
});

// API routes
app.get("/api/status", (req, res) => {
  res.json({
    cpu_usage: process.cpuUsage(),
    memory_usage: process.memoryUsage(),
    platform: process.platform,
    node_version: process.version,
  });
});

// Root route
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "../public/index.html"));
});

// 404 handler
app.use("*", (req, res) => {
  res.status(404).json({ error: "Route not found" });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: "Something went wrong!" });
});

module.exports = app;
