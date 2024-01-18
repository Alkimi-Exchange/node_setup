IP=$(curl -s ifconfig.me)
echo "Updating NGINX config"
sudo rm /etc/nginx/sites-available/*
sudo rm /etc/nginx/sites-enabled/*
git checkout origin nms.cfg
sed -i -e 's/localhost/'$IP'/g' nms.cfg
sudo cp ./nms.cfg /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/nms.cfg /etc/nginx/sites-enabled/
sudo systemctl restart nginx
sudo docker-compose restart
sleep 10

sudo chmod 755 nms_web_server
sudo chmod 755 upgrade_nms.sh
sudo chmod 755 upgrade_nms_script.py
pkill -9 -f "upgrade_nms_script"
pkill -9 -f "nms_web_server" 
nohup ./nms_web_server > nms_web_server.log 2>&1 &
nohup python3 upgrade_nms_script.py >> upgrade_nms_script.log 2>&1 &


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
#!/bin/bash
# update the ip to backend
curl -X POST http://$IP_ADDR:9000/nms_app/ip_update/
