IP_ADDR=$(wget -qO- ifconfig.me) 
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
