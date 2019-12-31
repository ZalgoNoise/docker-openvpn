#!/bin/bash
_datapath='/etc/openvpn'
_genclient(){
     echo "Creating a client. Please enter a username: "
     read OVPN_CLIENT
     bash /usr/local/bin/easyrsa build-client-full $OVPN_CLIENT nopass \
     && bash /usr/local/bin/ovpn_getclient $OVPN_CLIENT > $_datapath/clients/$OVPN_CLIENT.ovpn
}
# Fetch needed environment variables

if [ -z $OVPN_SERVER ]
then echo -n "Define your public server IP (i.e.: 255.255.255.255): "
     read OVPN_SERVER
fi

if [ -z $OVPN_SUBNET ]
then echo -n "Define your custom subnet (i.e.: 10.8.0.0): "
     read OVPN_SUBNET
fi


# Checking if files already exist
# Setting up server
if ! [ -f $_datapath/openvpn.conf ] || ! [ -f $_datapath/ovpn_env.sh ] || ! [ -d $_datapath/ccd ]
then bash /usr/local/bin/ovpn_genconfig \
     -u udp://${OVPN_SERVER} \
     -p "redirect-gateway def1 bypass-dhcp" \
     -e "sndbuf 0" \
     -e "rcvbuf 0" \
     -e "topology subnet" \
     -e "ifconfig-pool-persist ipp.txt" \
     -E 'pull-filter ignore "route-gateway"' \
     -E "route 0.0.0.0 192.0.0.0 net_gateway" \
     -E "route 64.0.0.0 192.0.0.0 net_gateway" \
     -E "route 128.0.0.0 192.0.0.0 net_gateway" \
     -E "route 192.0.0.0 192.0.0.0 net_gateway" \
     -E "sndbuf 0" \
     -E "rcvbuf 0" \
     -E "resolv-retry infinite" \
     -E "persist-key" \
     -E "persist-tun" \
     -E "setenv opt block-outside-dns" \
     -E "key-direction 1" \
     -E "verb 3" \
     -s "${OVPN_SUBNET}/24" \
     -d \
     -N \
     -z
fi

# Setting up keys

if ! [ -d $_datapath/pki ]
then bash usr/local/bin/ovpn_initpki
fi

# Setting up user

if ! [ -d $_datapath/clients ]
then mkdir $_datapath/clients
fi

if ! [ -f $_datapath/clients/* ]
then
   _genclient
fi

bash /usr/local/bin/ovpn_run &
