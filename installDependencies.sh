#!/bin/bash

echo " deleting old lists " &&
rm -rf /var/lib/apt/lists/* && # handles deleting old lists that link to unsigned packages?
echo " apt-get update " &&
apt-get update &&
echo " apt-get install " &&
apt-get install -y openvpn easy-rsa &&
echo " install azure cli " &&
curl -sL https://aka.ms/InstallAzureCLIDeb | bash &&
echo "dependency install complete"