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

# attempt to download config/credentials from Azure blob storage
if [ ! -f /etc/openvpn/ta.key ]; then
    echo "attempting download of credentials from Azure blob storage"
    bash downloadCredentials.sh $storageAccountKey || echo "download failed"
fi

# generate all config/credentials if not on disk
if [ ! -f /etc/openvpn/ta.key ]; then
  echo " make-cadir " &&
  make-cadir ~/openvpn-ca || echo \\"make-cadir failed\\" &&
  cd ~/openvpn-ca &&
  ln -s /etc/ssl/openssl.cnf ~/openvpn-ca/openssl.cnf || echo \\"link exists\\" &&
  chmod +x easyrsa && # Do I need this?
  ./easyrsa init-pki &&
  # TODO: replace test with vmName
  echo -e "test" | ./easyrsa build-ca nopass &&
  ./easyrsa gen-dh || echo \\"gen-dh failure\\"  &&
  ./easyrsa build-server-full server nopass || echo \\"build-server-full failure\\" &&
  ./easyrsa build-client-full testClient nopass || echo \\"build-client-full failure\\" &&

  cp pki/ca.crt pki/private/ca.key pki/issued/server.crt pki/private/server.key pki/dh.pem /etc/openvpn &&
  mv /etc/openvpn/dh.pem /etc/openvpn/dh2048.pem &&

  openvpn --genkey tls-auth /etc/openvpn/ta.key &&
  bash uploadCredentials.sh $storageAccountKey
fi

# updating config settings, can be run every time
cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/server.conf &&
echo -e '\npush "redirect-gateway def1"' >> /etc/openvpn/server.conf &&

# TODO: replace with dns server behind vpn
echo -e "\npush \"dhcp-option DNS 8.8.8.8\"" >> /etc/openvpn/server.conf &&
echo -e "\npush \"remote-gateway $publicIp\"" >> /etc/openvpn/server.conf &&

# https://www.sindastra.de/p/807/quickly-kill-ipv6-leaks-on-your-openvpn-server#:~:text=We%20can%20quickly%20solve%20this%20by%20giving%20our,usually%20found%20at%20%2Fetc%2Fopenvpn%2Fserver.conf%20or%20%2Fetc%2Fopenvpn%2Fserver%2Fserver.conf%20or%20similar.
# Assign the network address of 2001:db8:0:123::/64 to your OpenVPN server
echo -e "\nserver-ipv6 2001:db8:0:123::/64" >> /etc/openvpn/server.conf &&
# and then push a route so that all IPv6-internet addresses on the client side will be connected to through the VPN server.
echo -e "\npush \"route-ipv6 2000::/3\"" >> /etc/openvpn/server.conf &&
# disable ipv6, prevent ipv6 client leak
echo -e "\nnet.ipv6.conf.all.forwarding=0" >> /etc/sysctl.conf &&

# https://askubuntu.com/questions/1022770/route-all-traffic-redirect-gateway-not-working-openvpn
# forwarding traffic to 10.8.0.0 address space
echo -e "\nnet.ipv4.ip_forward=1" >> /etc/sysctl.conf &&
sysctl -p /etc/sysctl.conf &&
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

systemctl reload-or-restart openvpn@server