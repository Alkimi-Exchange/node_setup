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
  -H 'authorization: LK49JOGW3BEQGN70HYHX1D42448EJ98A' \
  -d '')
  NODE_ID=$(echo "$NODE_ID" | cut -d ":" -f 3 | sed 's/.$//')
echo " Your Node id Is:  $NODE_ID "
#!/bin/bash
# update the ip to backend
curl -X POST http://$IP_ADDR:9000/nms_app/ip_update/
