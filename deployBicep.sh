#!/bin/bash

az deployment group create --resource-group vpn --template-file openvpn.bicep --parameters adminUsername=testUser123! adminPassword=test123! installScriptBase64=$(cat install.sh | base64 -w0) uploadCredentialsScriptBase64=$(cat uploadCredentials.sh | base64 -w0)