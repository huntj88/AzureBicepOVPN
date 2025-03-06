#!/bin/bash

storageAccountKey=$1
if [ -z "$storageAccountKey" ]; then
  echo "Usage: $0 <storageAccountKey>"
  exit 1
fi

# wait for container to be created
sleep 5

upload() {
    local name=$1
    az storage blob upload --overwrite -c vpn --account-key $storageAccountKey --account-name vpnstorage006314d62eef4d -f $name -n $(basename $name) || echo "Failed to upload $name"
}

upload /etc/openvpn/dh2048.pem
upload /etc/openvpn/ca.crt
upload /etc/openvpn/ca.key
upload /etc/openvpn/server.crt
upload /etc/openvpn/server.key
upload /etc/openvpn/ta.key

# TODO: clients should generate their own keys
upload ~/openvpn-ca/pki/private/testClient.key
upload ~/openvpn-ca/pki/issued/testClient.crt
