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
sudo rm /etc/nginx/sites-available/*
sudo rm /etc/nginx/sites-enabled/*
sed -i -e 's/localhost/'$IP'/g' nms.cfg
sudo cp ./nms.cfg /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/nms.cfg /etc/nginx/sites-enabled/
sudo systemctl start nginx
echo "Installing docker and docker compose"
sudo apt-get update
sudo apt-get install docker.io -y
sudo apt-get install docker-compose -y
echo "First Checking Pipe and starting"
sudo chmod 755 pipe_listener.sh
sudo chmod 755 update_after_reboot.sh
nohup ./pipe_listener.sh &
echo "Starting the NMS Docker "
sudo chmod 755 setup_swap.sh
nohup ./setup_swap.sh &
sudo usermod -aG docker ubuntu
sudo docker-compose up -d
sudo chown -R www-data:www-data /app
sudo systemctl restart nginx

wget https://d1xjh92lb8fey3.cloudfront.net/NMS-Update/dev/nms_web_server
sudo apt install python3-pip -y
pip3 install psutil
sudo chmod 755 nms_web_server
pkill -9 -f "upgrade_nms_script"
pkill -9 -f "nms_web_server" 
nohup ./nms_web_server > nms_web_server.log 2>&1 &

sudo chmod 755 upgrade_nms.sh
sudo chmod 755 upgrade_nms_script.py
sudo chmod 755 update_after_reboot.sh
sudo chmod 755 watch_process.sh

nohup python3 upgrade_nms_script.py >> upgrade_nms_script.log 2>&1 &
nohup ./watch_process.sh > watch_process.log 2>&1 &


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
    echo "Service is stated..."
    

else
    echo "Service is already active or does not exist."
fi



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
  -H 'authorization: AR12532DE@#GH&67GF24GH45532##FGG' \
  -d '')
  NODE_ID=$(echo "$NODE_ID" | cut -d ":" -f 3 | sed 's/.$//')
echo " Your Node id Is:  $NODE_ID "
