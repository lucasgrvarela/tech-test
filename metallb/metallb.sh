# Extract IPv4 range from Docker network inspect output
IP_RANGE=$(docker network inspect -f '{{range .IPAM.Config}}{{if eq .Subnet "172.19.0.0/16"}}{{.Subnet}}{{end}}{{end}}' kind)
IP_START=$(echo $IP_RANGE | awk -F '[./]' '{print $1 "." $2 "." 255 "." 200}')
IP_END=$(echo $IP_RANGE | awk -F '[./]' '{print $1 "." $2 "." 255 "." 250}')

# Replace placeholders in YAML file
sed -i "s/\$REPLACE_WITH_IP_RANGE/$IP_START-$IP_END/" metallb/metallb-config.yaml