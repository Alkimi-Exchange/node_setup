#! /bin/bash -xv
shopt -s extglob  ## this is to add exclude a folder in a cp command
cd /home/ubuntu/node_setup
sudo docker-compose down
sudo pkill -9 -f "nms_web_server" 
folder_name="nms"$(date +%Y%m%d%H%M%S)
sudo rm -f nms_web_server
mkdir -p /home/ubuntu/node_backup/"$folder_name"
cp -rp /home/ubuntu/node_setup/ /home/ubuntu/node_backup/"$folder_name"
git checkout .
git pull
wget https://d1xjh92lb8fey3.cloudfront.net/NMS-Update/dev/nms_web_server
chmod 755 nms_web_server
chmod 755 upgrade_nms.sh
sleep 2

# Retry up to 3 times
for attempt in {1..3}; do
    # Forcefully kill the process on port 8001
    sudo lsof -ti:8001 | xargs kill -9

    # Attempt to start the server
    nohup ./nms_web_server > nms_web_server.log 2>&1 &
    
    # Sleep for a short duration to give the server time to start
    sleep 4

    # Check if the server is running on port 8001 using ss
    if ss -ltn | grep ':8001'; then
        echo "NMS Upgrade completed Successfully"
        break  # Break the loop if the server started successfully
    else
        echo "Retry $attempt: NMS Upgrade failed. Retrying..."
    fi
done

# If the loop completes without success
if [ $? -ne 0 ]; then
    echo "NMS Upgrade failed after multiple attempts."
fi
sudo docker-compose up -d
sleep 2
# Check if the service exists and is running
SERVICE_STATUS=$(systemctl is-active nms_service.service 2>/dev/null)

# Define paths
EXISTING_SERVICE_FILE="/etc/systemd/system/nms_service.service"
NEW_SERVICE_FILE="/home/ubuntu/node_setup/nms_service.service"
BACKUP_SERVICE_FILE="/home/ubuntu/node_setup/nms_service_backup.service"

# Check if the service is not active
if [ "$SERVICE_STATUS" != "active" ]; then
    # Backup and remove existing service file if it exists
    if [ -f "$EXISTING_SERVICE_FILE" ]; then
        echo "Backing up and removing existing service file: $EXISTING_SERVICE_FILE"
        sudo cp "$EXISTING_SERVICE_FILE" "$BACKUP_SERVICE_FILE"
        sudo rm "$EXISTING_SERVICE_FILE"
    fi

    # Copy new service file
    echo "Copying new service file: $NEW_SERVICE_FILE to $EXISTING_SERVICE_FILE"
    sudo cp "$NEW_SERVICE_FILE" "$EXISTING_SERVICE_FILE"

    # Set permissions
    echo "Setting permissions for $EXISTING_SERVICE_FILE"
    sudo chmod 644 "$EXISTING_SERVICE_FILE"

    # Reload systemd daemon to recognize changes
    echo "Reloading systemd daemon"
    sudo systemctl daemon-reload

    # Enable the service to start on boot
    echo "Enabling the service to start on boot"
    sudo systemctl enable nms_service.service
else
    echo "Service is already active or does not exist."
fi

