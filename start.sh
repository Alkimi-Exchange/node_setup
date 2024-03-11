if [ $USER != "ubuntu" ] ; then
        echo "You are not executing this script as Ubuntu user"
        echo "Stopping the installtion"
        echo "login as ubuntu user to continue installation"
        exit
fi
IP=$(curl -s ifconfig.me)
echo "Installing NGINX"
sudo apt-get update
sudo apt install openjdk-17-jdk openjdk-17-jre -y
sudo apt-get install nginx -y
sudo apt-get install dos2unix -y

echo "Installing docker and docker compose"
sudo apt-get update
sudo apt-get install docker.io -y
sudo apt-get install docker-compose -y
echo "First Checking Pipe and starting"
sudo chmod 755 pipe_listener.sh
sudo chmod 755 update_after_reboot.sh
nohup ./pipe_listener.sh &
echo "Starting the NMS Docker "
sudo usermod -aG docker ubuntu
sudo chown -R www-data:www-data /app
wget https://d1xjh92lb8fey3.cloudfront.net/NMS-Update/dev/nms_web_server
sudo apt install python3-pip -y
pip3 install psutil

#------------------------systemctl----------------------------------
# Check if the service is running
EXISTING_SERVICE_FILE="/etc/systemd/system/nms_service.service"
NEW_SERVICE_FILE="/home/ubuntu/node_setup/nms_service.service"

# Remove existing service file if it exists
if [ -f "$EXISTING_SERVICE_FILE" ]; then
    echo "Removing existing service file: $EXISTING_SERVICE_FILE"
    sudo rm "$EXISTING_SERVICE_FILE"
fi

# Copy new service file
echo "Copying new service file: $NEW_SERVICE_FILE to $EXISTING_SERVICE_FILE"
sudo cp "$NEW_SERVICE_FILE" "$EXISTING_SERVICE_FILE"

# Set permissions
echo "Setting permissions for $EXISTING_SERVICE_FILE"
sudo chmod 644 "$EXISTING_SERVICE_FILE"

# Reload systemd daemon
echo "Reloading systemd daemon"
sudo systemctl daemon-reload

# Restart the service
echo "Restarting nms_service.service"
sudo systemctl restart nms_service.service


sleep 10
IP_ADDR=$(wget -qO- ifconfig.me) 
echo "### Node Setup Completed  ##"
echo " "
echo " Please note down below details"
echo " ------ ---- ---- ----- -------"
echo " "
echo " You node IP Address: $IP_ADDR"
URL="http://$IP_ADDR:8000/nms_app/get_node_id/"
NODE_ID=$(curl  -s -X 'POST' \
  $URL \
  -H 'accept: application/json' \
  -H 'authorization: E58YS7YHN8A5848Y5GC7SUAMNVFXJRZB' \
  -d '')
  NODE_ID=$(echo "$NODE_ID" | cut -d ":" -f 3 | sed 's/.$//')
echo " Your Node id Is:  $NODE_ID "
