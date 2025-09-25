#!/bin/bash
set -e

echo "🚀 Starting deployment process..."

# Configuration
APP_DIR="/var/www/app"
BACKUP_DIR="/var/www/backup"
SERVICE_NAME="app"

# Create necessary directories
sudo mkdir -p $APP_DIR
sudo mkdir -p $BACKUP_DIR

# Change ownership to ubuntu user
sudo chown -R ubuntu:ubuntu $APP_DIR
sudo chown -R ubuntu:ubuntu $BACKUP_DIR

# Navigate to app directory
cd $APP_DIR

echo "📦 Extracting deployment package..."
# Extract the deployment package
tar -xzf /tmp/deployment.tar.gz

echo "📋 Installing dependencies..."
# Install only production dependencies
npm ci --only=production

echo "🔄 Managing application process..."
# Stop the current application (if running)
pm2 stop $SERVICE_NAME || echo "No existing process to stop"

# Delete old process
pm2 delete $SERVICE_NAME || echo "No existing process to delete"

echo "🌍 Setting environment variables..."
# Set production environment
export NODE_ENV=production
export PORT=3000
export HOST=0.0.0.0
export DEPLOYMENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

echo "🚀 Starting application with PM2..."
# Start the application with PM2
pm2 start src/server.js --name $SERVICE_NAME --env production

# Save PM2 configuration
pm2 save

# Setup PM2 to start on system boot
pm2 startup ubuntu -u ubuntu --hp /home/ubuntu || echo "PM2 startup already configured"

echo "🔍 Performing health check..."
# Wait for application to start
sleep 10

# Health check
for i in {1..5}; do
    if curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
        echo "✅ Health check passed!"
        break
    else
        echo "⏳ Health check attempt $i failed, retrying..."
        sleep 5
    fi
    
    if [ $i -eq 5 ]; then
        echo "❌ Health check failed after 5 attempts"
        pm2 logs $SERVICE_NAME --lines 20
        exit 1
    fi
done

echo "🎉 Deployment completed successfully!"
echo "📊 Application status:"
pm2 status