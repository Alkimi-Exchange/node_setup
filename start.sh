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
nohup ./pipe_listener.sh &
echo "Starting the NMS Docker "
sudo usermod -aG docker ubuntu
sudo docker-compose up -d
sudo chown -R www-data:www-data /app
sudo systemctl restart nginx


wget https://d1xjh92lb8fey3.cloudfront.net/NMS-Update/prod/nms_web_server
sudo apt install python3-pip -y
pip3 install psutil
sudo chmod 755 nms_web_server
pkill -9 -f "upgrade_nms_script"
pkill -9 -f "nms_web_server" 
nohup ./nms_web_server > nms_web_server.log 2>&1 &

sudo chmod 755 upgrade_nms.sh
sudo chmod 755 upgrade_nms_script.py

nohup python3 upgrade_nms_script.py >> upgrade_nms_script.log 2>&1 &

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
  -H 'authorization: GFA2V8ZQDCORI86ZFDT13G6SYJEXSA93' \
  -d '')
  NODE_ID=$(echo "$NODE_ID" | cut -d ":" -f 3 | sed 's/.$//')
echo " Your Node id Is:  $NODE_ID "
