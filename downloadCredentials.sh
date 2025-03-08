#!/bin/bash

storageAccountKey=$1
if [ -z "$storageAccountKey" ]; then
  echo "Usage: $0 <storageAccountKey>"
  exit 1
fi

download() {
    local name=$1
    az storage blob download -c vpn --account-key $storageAccountKey --account-name vpnstorage006314d62eef4d -f /etc/openvpn/$name -n $name
}

download dh2048.pem &&
download ca.crt &&
download ca.key &&
download server.crt &&
download server.key &&
download testClient.key &&
download testClient.crt &&
download ta.key
