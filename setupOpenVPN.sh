#!/bin/bash

# generate all config if last part of if statement is has not previously finished
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

  openvpn --genkey tls-auth /etc/openvpn/ta.key
fi

# updating config settings, can be run every time
cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/server.conf &&
echo -e '\npush "redirect-gateway def1"' >> /etc/openvpn/server.conf &&

# TODO: replace with dns server behind vpn
# echo -e "\npush \"dhcp-option DNS TODO.ip.goes.here\"" >> /etc/openvpn/server.conf
echo -e "\npush \"dhcp-option DNS 8.8.8.8\"" >> /etc/openvpn/server.conf &&
echo -e "\nnet.ipv4.ip_forward=1" >> /etc/sysctl.conf &&
sysctl -p /etc/sysctl.conf
