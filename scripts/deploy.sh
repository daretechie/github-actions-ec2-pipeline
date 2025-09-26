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
sudo chown -R ${USER}:${USER} $APP_DIR
sudo chown -R ${USER}:${USER} $BACKUP_DIR

# Capture previous release before making any changes
PREVIOUS_RELEASE_DIR=""
if [ -L "$CURRENT_RELEASE_DIR" ]; then
  PREVIOUS_RELEASE_DIR=$(readlink -f $CURRENT_RELEASE_DIR)
fi

# Create new release directory
mkdir -p $NEW_RELEASE_DIR

echo "📦 Extracting deployment package..."
# Extract the deployment package
tar -xzf /tmp/deployment.tar.gz -C $NEW_RELEASE_DIR

# Ensure src directory exists


echo "📋 Installing dependencies..."
# Install only production dependencies
cd $NEW_RELEASE_DIR
npm ci --omit=dev

echo "🔄 Managing application process..."

# Point current symlink to new release BEFORE managing PM2
ln -nfs $NEW_RELEASE_DIR $CURRENT_RELEASE_DIR

# Manage PM2 with stable path pointing at current symlink
if pm2 list | grep -q $SERVICE_NAME; then
  echo "🔄 Restarting application with PM2 to update script path..."
  # Replace existing process to ensure it uses the stable current symlink path
  pm2 delete $SERVICE_NAME || true
  pm2 start $CURRENT_RELEASE_DIR/src/server.js --name $SERVICE_NAME --env production
else
  echo "🚀 Starting application with PM2..."
  export NODE_ENV=production
  export PORT=3000
  export HOST=0.0.0.0
  export DEPLOYMENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
  pm2 start $CURRENT_RELEASE_DIR/src/server.js --name $SERVICE_NAME --env production
fi

# Do NOT move previous release yet; wait until health check passes

# Symlink already updated above

# Save PM2 configuration
pm2 save

# Setup PM2 to start on system boot
pm2 startup || echo "PM2 startup already configured"

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

# Now that deployment is healthy, back up the previous release if it exists and is different
if [ -n "$PREVIOUS_RELEASE_DIR" ] && [ -d "$PREVIOUS_RELEASE_DIR" ] && [ "$PREVIOUS_RELEASE_DIR" != "$NEW_RELEASE_DIR" ]; then
  echo "Creating backup of the previous release..."
  BACKUP_NAME=$(basename $PREVIOUS_RELEASE_DIR)
  mv $PREVIOUS_RELEASE_DIR "$BACKUP_DIR/$BACKUP_NAME" || echo "Previous release already moved or missing"
fi

# Clean up old releases (keep the last 5)
echo "🧹 Cleaning up old releases..."
ls -dt $RELEASES_DIR/* | tail -n +6 | xargs -r rm -rf

echo "🎉 Deployment completed successfully!"
echo "📊 Application status:"
pm2 status