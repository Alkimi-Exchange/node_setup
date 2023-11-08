#! /bin/bash -xv
shopt -s extglob  ## this is to add exlude a folder in a cp command
cd /home/ubuntu/node_setup
sudo docker-compose down
pkill -9 -f "nms_web_server" 
folder_name="nms"$(date +%Y%m%d%H%M%S)
mkdir -p /home/ubuntu/node_backup/"$folder_name"
cp -rp /home/ubuntu/node_setup/ /home/ubuntu/node_backup/"$folder_name"
git checkout .
git pull
wget  https://d1xjh92lb8fey3.cloudfront.net/NMS-Update/stg/nms_web_server
chmod 755 nms_web_server
sudo docker-compose up -d
chmod 755 upgrade_nms.sh
sleep 2
nohup ./nms_web_server > nms_web_server.log 2>&1 &
echo "NMS Upgrade completed Successfully" > /home/ubuntu/node_backup/nms_upgrade.log

