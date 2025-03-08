#!/bin/bash

case $1 in 
    --up)
        vmUp=true ;;
    --down)
        vmUp=false ;;    
    *) 
        echo "Unknown parameter passed: $1"; exit 1 ;;
esac

az deployment group create \
 --mode complete \
 --resource-group openvpn \
 --template-file openvpn.bicep \
 --parameters \
   vmUp=$vmUp \
   adminUsername=testUser123! \
   adminPassword=test123! \
   installDependenciesB64=$(cat installDependencies.sh | base64 -w0) \
   downloadCredentialsB64=$(cat downloadCredentials.sh | base64 -w0) \
   setupOpenVPNB64=$(cat setupOpenVPN.sh | base64 -w0) \
   uploadCredentialsB64=$(cat uploadCredentials.sh | base64 -w0) \
   vmInitB64=$(cat vmInit.sh | base64 -w0)
