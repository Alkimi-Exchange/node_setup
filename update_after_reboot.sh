#!/bin/bash

export HOME=/home/ubuntu
# Change directory to the script's directory
cd "$(dirname "$0")" || exit

# Function to handle errors
handle_error() {
    echo "Error occurred: $1"
    exit 1
}

# Error handling for critical commands
check_command() {
    "$@" || handle_error "Failed to execute: $*"
}

# Create NGINX sites-available directory if it doesn't exist
sudo mkdir -p /etc/nginx/sites-available

# Obtain the public IP address
IP=$(curl -s ifconfig.me) || handle_error "Failed to get IP address"

echo "Updating NGINX config"
# Remove existing NGINX config files if the directory exists
if [ -d "/etc/nginx/sites-available" ]; then
    # Check if there are any files to remove
    if [ "$(ls -A /etc/nginx/sites-available)" ]; then
        check_command sudo rm /etc/nginx/sites-available/* || handle_error "Failed to remove NGINX config files"
    fi
    if [ "$(ls -A /etc/nginx/sites-enabled)" ]; then
        check_command sudo rm /etc/nginx/sites-enabled/* || handle_error "Failed to remove NGINX config files"
    fi
fi
git config --global --add safe.directory /home/ubuntu/node_setup
# Assuming nms.cfg is in the current directory and is versioned with Git
check_command git checkout origin nms.cfg || handle_error "Failed to checkout nms.cfg"
sed -i -e 's/localhost/'"$IP"'/g' nms.cfg || handle_error "Failed to replace IP in nms.cfg"
check_command sudo cp ./nms.cfg /etc/nginx/sites-available/ || handle_error "Failed to copy nms.cfg to NGINX sites-available"
check_command sudo ln -s /etc/nginx/sites-available/nms.cfg /etc/nginx/sites-enabled/ || handle_error "Failed to create symlink for NGINX config"
check_command sudo systemctl restart nginx || handle_error "Failed to restart NGINX"

# Bring down Docker containers
sudo docker-compose down || handle_error "Failed to bring down Docker containers"
sleep 2

# Bring up Docker containers
sudo docker-compose up -d || handle_error "Failed to bring up Docker containers"
sleep 10

# Set permissions for scripts
check_command sudo chmod 755 nms_web_server || handle_error "Failed to set permissions for nms_web_server"
check_command sudo chmod 755 upgrade_nms.sh || handle_error "Failed to set permissions for upgrade_nms.sh"
check_command sudo chmod 755 upgrade_nms_script.py || handle_error "Failed to set permissions for upgrade_nms_script.py"

# Terminate existing instances of upgrade_nms_script and nms_web_server
pkill -9 -f "upgrade_nms_script"
pkill -9 -f "nms_web_server"

# Start nms_web_server and upgrade_nms_script in the background
nohup ./nms_web_server > nms_web_server.log 2>&1 &
nohup python3 upgrade_nms_script.py >> upgrade_nms_script.log 2>&1 &

# Obtain the updated IP address
IP_ADDR=$(wget -qO- ifconfig.me) || handle_error "Failed to get updated IP address"
echo "### Node Setup Completed  ##"
echo " "
echo " Please note down below details"
echo " ------ ---- ---- ----- -------"
echo " "
echo " Your node IP Address: $IP_ADDR"
URL="http://$IP_ADDR:8000/nms_app/get_node_id/"
NODE_ID=$(curl  -s -X 'POST' \
  $URL \
  -H 'accept: application/json' \
  -H 'authorization: AR12532DE@#GH&67GF24GH45532##FGG' \
  -d '') || handle_error "Failed to get Node ID"
NODE_ID=$(echo "$NODE_ID" | cut -d ":" -f 3 | sed 's/.$//')
echo " Your Node ID Is:  $NODE_ID "

# Update the IP address to the backend
curl -X POST "http://$IP_ADDR:9000/nms_app/ip_update/" || handle_error "Failed to update IP address to the backend"
