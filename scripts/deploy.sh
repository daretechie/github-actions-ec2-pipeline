#!/bin/bash
set -e

# Configuration
APP_DIR=${1:-"/var/www/app"}
BACKUP_DIR=${2:-"/var/www/backup"}
SERVICE_NAME=${3:-"app"}
RELEASES_DIR="$APP_DIR/releases"
CURRENT_RELEASE_DIR="$APP_DIR/current"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
NEW_RELEASE_DIR="$RELEASES_DIR/$TIMESTAMP"

echo "🚀 Starting deployment process..."

# Create necessary directories
sudo mkdir -p $RELEASES_DIR
sudo mkdir -p $BACKUP_DIR
sudo chown -R ubuntu:ubuntu $APP_DIR
sudo chown -R ubuntu:ubuntu $BACKUP_DIR

# Create new release directory
mkdir -p $NEW_RELEASE_DIR

echo "📦 Extracting deployment package..."
# Extract the deployment package
tar -xzf /tmp/deployment.tar.gz -C $NEW_RELEASE_DIR

# Ensure src directory exists


echo "📋 Installing dependencies..."
# Install only production dependencies
cd $NEW_RELEASE_DIR
npm ci --only=production

echo "🔄 Managing application process..."

# Check if the service is already running
if pm2 list | grep -q $SERVICE_NAME; then
  echo "🔄 Reloading application with PM2 for zero-downtime deployment..."
  pm2 reload $SERVICE_NAME
else
  echo "🚀 Starting application with PM2..."
  # Set production environment
  export NODE_ENV=production
  export PORT=3000
  export HOST=0.0.0.0
  export DEPLOYMENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
  
  pm2 start $NEW_RELEASE_DIR/src/server.js --name $SERVICE_NAME --env production
fi

# Create a backup of the previous release
if [ -L "$CURRENT_RELEASE_DIR" ]; then
  PREVIOUS_RELEASE_DIR=$(readlink -f $CURRENT_RELEASE_DIR)
  if [ -d "$PREVIOUS_RELEASE_DIR" ]; then
    echo "Creating backup of the previous release..."
    BACKUP_NAME=$(basename $PREVIOUS_RELEASE_DIR)
    mv $PREVIOUS_RELEASE_DIR "$BACKUP_DIR/$BACKUP_NAME"
  fi
fi

# Symlink the new release to current
ln -nfs $NEW_RELEASE_DIR $CURRENT_RELEASE_DIR

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
        
        echo "- Rolling back to the previous release..."
        
        # Find the latest backup
        LATEST_BACKUP=$(ls -td $BACKUP_DIR/* | head -1)
        
        if [ -d "$LATEST_BACKUP" ]; then
          # Move the failed release to the backup directory
          mv $NEW_RELEASE_DIR "$BACKUP_DIR/failed-$TIMESTAMP"
          
          # Restore the latest backup
          mv $LATEST_BACKUP $RELEASES_DIR/
          
          # Symlink to the restored release
          RESTORED_RELEASE_DIR="$RELEASES_DIR/$(basename $LATEST_BACKUP)"
          ln -nfs $RESTORED_RELEASE_DIR $CURRENT_RELEASE_DIR
          
          # Reload the application
          pm2 reload $SERVICE_NAME
          
          echo "✅ Rollback completed successfully!"
        else
          echo "❌ No backup found to rollback to."
        fi
        
        exit 1
    fi
done

# Clean up old releases (keep the last 5)
echo "🧹 Cleaning up old releases..."
ls -dt $RELEASES_DIR/* | tail -n +6 | xargs -r rm -rf

echo "🎉 Deployment completed successfully!"
echo "📊 Application status:"
pm2 status