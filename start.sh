IP=$(curl -s ifconfig.me)
echo "Installing NGINX"
sudo apt-get update
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
nohup ./pipe_listener.sh &
echo "Starting the NMS Docker "
sudo docker-compose up -d
sudo chown -R www-data:www-data /app
sudo systemctl restart nginx


wget https://d1xjh92lb8fey3.cloudfront.net/NMS-Update/dev/nms_web_server
sudo apt install python3-pip
pip3 install psutil
sudo chmod 755 nms_web_server

nohup ./nms_web_server &

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
  -H 'authorization: AR12532DE@#GH&67GF24GH45532$##FGG' \
  -d '')
  NODE_ID=$(echo "$NODE_ID" | cut -d ":" -f 3 | sed 's/.$//')
echo " Your Node id Is:  $NODE_ID "
