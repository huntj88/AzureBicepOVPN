apt-get update && 
apt-get install -y openvpn easy-rsa && 
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
openvpn --genkey tls-auth ta.key &&
pwd && 
ls &&
echo "                pki: " &&
ls pki &&
echo "                pki/issued: " &&
ls pki/issued &&
echo "                pki/private: " &&
ls pki/private &&
cp pki/ca.crt pki/private/ca.key pki/issued/server.crt pki/private/server.key pki/dh.pem ta.key /etc/openvpn && 
mv /etc/openvpn/dh.pem /etc/openvpn/dh2048.pem &&
cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/server.conf &&
systemctl start openvpn@server