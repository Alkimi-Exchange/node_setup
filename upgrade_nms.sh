#! /bin/bash
shopt -s extglob  ## this is to add exlude a folder in a cp command
cd /home/ubuntu/node_setup
docker-compose down
server_pid="$(<webserver_pid.txt)"
echo "SERVICER PID IS $server_pid"
folder_name="nms"$(date +%Y%m%d%H%M%S)
mkdir -p backup/"$folder_name"
cp -rp /home/ubuntu/node_setup/!(backup) backup/"$folder_name"
git checkout .
git pull
wget --backups=1 https://d1xjh92lb8fey3.cloudfront.net/NMS-Update/dev/nms_web_server
chmod 755 nms_web_server
nohup ./nms_web_server &
echo $! > webserver_pid.txt
docker-compose up -d
echo "NMS Upgrade completed Successfully" > backup/nms_upgrade.log
chmod 755 upgrade_nms.sh
