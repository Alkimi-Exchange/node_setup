#!/bin/bash
# Set environment variables
export HOME=/home/ubuntu/node_setup
# Change directory to the script's directory
cd "$HOME" || { echo "Failed to change directory. Exiting..."; exit 1; }

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
    # Check if there are files to remove in sites-available
    if [ "$(ls -A /etc/nginx/sites-available)" ]; then
        check_command sudo rm /etc/nginx/sites-available/* || handle_error "Failed to remove NGINX config files in sites-available"
    fi

    # Check if there are files to remove in sites-enabled
    if [ "$(ls -A /etc/nginx/sites-enabled)" ]; then
        check_command sudo rm /etc/nginx/sites-enabled/* || handle_error "Failed to remove NGINX config files in sites-enabled"
    fi
fi

git config --global --add safe.directory /home/ubuntu/node_setup
# Assuming nms.cfg is in the current directory and is versioned with Git
check_command git checkout origin nms.cfg || handle_error "Failed to checkout nms.cfg"
sed -i -e 's/localhost/'"$IP"'/g' nms.cfg || handle_error "Failed to replace IP in nms.cfg"
check_command sudo cp ./nms.cfg /etc/nginx/sites-available/ || handle_error "Failed to copy nms.cfg to NGINX sites-available"
check_command sudo ln -s /etc/nginx/sites-available/nms.cfg /etc/nginx/sites-enabled/ || handle_error "Failed to create symlink for NGINX config"
check_command sudo systemctl start nginx || handle_error "Failed to restart NGINX"
sudo usermod -aG docker ubuntu
# Bring up Docker containers
sudo docker-compose up -d || handle_error "Failed to bring up Docker containers"
sleep 1
sudo chown -R www-data:www-data /app
check_command sudo systemctl restart nginx || handle_error "Failed to restart NGINX"

# Terminate existing instances of upgrade_nms_script and nms_web_server
sudo pkill -9 -f "nms_web_server"
sudo pkill -9 -f "watch_process"
# Define an array of file names to remove
files_to_remove=("watch_process.log" "upgrade_nms_script.log","nms_web_server.log")

# Loop through each file name
for file in "${files_to_remove[@]}"; do
    # Check if the file exists
    if [ -f "$file" ]; then
        echo "Removing $file..."
        sudo rm -f "$file"
        echo "$file removed."
    else
        echo "$file does not exist. Skipping removal."
    fi
done

# Start nms_web_server and upgrade_nms_script in the background
nohup ./nms_web_server > nms_web_server.log 2>&1 &
nohup ./watch_process.sh > watch_process.log 2>&1 &
# Check if upgrade_nms_script.py is running
if pgrep -f "upgrade_nms_script.py" >/dev/null; then
    echo "upgrade_nms_script.py is already running, skipping..."
else
    nohup python3 upgrade_nms_script.py >> upgrade_nms_script.log 2>&1 &
fi
sudo docker-compose restart
sleep 12

get_public_ip() {
    local sources=(
        "https://ifconfig.me"
        "https://api64.ipify.org"
        "https://ipinfo.io/ip"
        "http://checkip.amazonaws.com"
        "https://myexternalip.com/raw"
        "https://ipecho.net/plain"
    )
    for url in "${sources[@]}"; do
        IP_ADDR=$(curl -s --max-time 5 "$url" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')
        if [[ -n "$IP_ADDR" ]]; then
            echo "$IP_ADDR"
            return
        fi
    done

    echo "Error: Unable to retrieve public IP address." >&2
    exit 1
}

# Get public IP
IP_ADDR=$(get_public_ip)
echo "### Validator Setup Completed  ##"
echo " "
echo " Please note down below details"
echo " ------ ---- ---- ----- -------"
echo " "
echo " You Validator IP Address: $IP_ADDR"
URL="http://127.0.0.1:8000/nms_app/get_node_id/"
NODE_ID=$(curl  -s -X 'POST' \
  $URL \
  -H 'accept: application/json' \
  -H 'authorization: NAN' \
  -d '')
  NODE_ID=$(echo "$NODE_ID" | cut -d ":" -f 3 | sed 's/.$//')
echo " Your Validator id Is:  $NODE_ID "
#!/bin/bash
# update the ip to backend
curl -X POST http://127.0.0.1:9000/nms_app/ip_update/
