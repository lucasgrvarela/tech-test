# Extract IPv4 range from Docker network inspect output
BASE_IP=$(docker network inspect kind | jq -r '.[0].IPAM.Config[0].Gateway' | cut -d "/" -f 1)
IP_START=$(echo $BASE_IP | awk -F '[./]' '{print $1 "." $2 "." 255 "." 200}')
IP_END=$(echo $BASE_IP | awk -F '[./]' '{print $1 "." $2 "." 255 "." 250}')

# Replace placeholders in YAML file
sed -i "s/\$REPLACE_WITH_IP_RANGE/$IP_START-$IP_END/" metallb/metallb-config.yaml