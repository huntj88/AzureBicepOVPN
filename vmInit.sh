#!/bin/bash

storageAccountKey=$1
if [ -z "$storageAccountKey" ]; then
  echo "Usage: $0 <storageAccountKey>"
  exit 1
fi

publicIp=$2
if [ -z "$publicIp" ]; then
  echo "Usage: $0 <publicIp>"
  exit 1
fi

bash installDependencies.sh &&
bash setupOpenVPN.sh $storageAccountKey $publicIp