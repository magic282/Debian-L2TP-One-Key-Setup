#! /bin/bash
#===============================================================================================
#   System Required:  Debian or Ubuntu (64bit)
#   Description:  Install L2TP for Debian or Ubuntu
#   Author: XoYo <xoyohome@163.com>
#   Intro:  http://blog.cnantaeus.com
#===============================================================================================

#===============================================================================================
# Well, I have tested, Debian 7 32 bit also works
#===============================================================================================

echo "#######################################################"
echo "L2TP service for Debian_7.0_x64"
echo
echo "Easy to install & add new account."
echo "only tested on Debian_7 x64 and x32."
echo "PS:Please make sure you are using root account."
echo "#######################################################"
echo
echo
echo "#################################"
echo "What do you want to do:"
echo "1) install l2tp & add an account"
echo "2) only add an account"
echo "#################################"
read x
if test $x -eq 1; then
	echo "Please input an username:"
	read u
	echo "Please input a password:"
	read p
    echo "Please input the secretkey:"
	read k

# Get ip address
IP=`ifconfig | grep 'inet addr:'| grep -v '127.0.0.*' | cut -d: -f2 | awk '{ print $1}' | head -1`;

echo
echo "##################################"
echo "Downloading the component"
echo "##################################"
#apt-get update
apt-get -y upgrade
apt-get -y install ppp strongswan xl2tpd

echo
echo "##################"
echo "Set up options.xl2tpd"
echo "##################"
cat > /etc/ppp/options.xl2tpd <<END
name l2tp
auth
require-mschap-v2
ms-dns 8.8.4.4
ms-dns 8.8.8.8
idle 1800
nodefaultroute
lock
nobsdcomp
novj
novjccomp
nologfd
lcp-echo-interval 5
lcp-echo-failure 5
END

# xl2tpd.conf
rm /etc/xl2tpd/xl2tpd.conf
cat > /etc/xl2tpd/xl2tpd.conf <<END
[global]
[lns default]
local ip = 10.10.10.1
ip range = 10.10.10.2-10.10.10.254
require chap = yes
refuse pap = yes
require authentication = yes
ppp debug = yes
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
name = l2tp
END

# ipsec.conf
rm /etc/ipsec.conf
cat > /etc/ipsec.conf <<END
config setup
        plutodebug=control
        nat_traversal=yes
        charonstart=yes
        plutostart=yes

conn %default
        ikelifetime=60m
        keylife=20m
        rekeymargin=3m
        keyingtries=1
        keyexchange=ikev1
        authby=secret

conn l2tp
        leftfirewall=yes
        pfs=no
        rekey=no
        left=$IP
        leftprotoport=17/1701
        rightsubnetwithin=0.0.0.0/0
        right=%any
        rightprotoport=17/%any
        dpdaction=clear
        auto=add

END

# ipsec.secrets
rm /etc/ipsec.secrets
cat > /etc/ipsec.secrets <<END
$IP %any : PSK "$k"
END

# add an account
rm /etc/ppp/chap-secrets
cat > /etc/ppp/chap-secrets <<END
$u  l2tp  $p  *
END

echo
echo "###############"
echo "Restarting service"
echo "###############"
service ipsec restart
service xl2tpd restart

echo
echo "################################################"
echo "Last step"
echo "################################################"
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -j SNAT --to-source $IP
echo "echo 1 > /proc/sys/net/ipv4/ip_forward" >> /etc/init.d/rc.local
echo "iptables -t nat -A POSTROUTING -j SNAT --to-source $IP" >> /etc/init.d/rc.local

echo
echo "##################################"
echo "Success!"
echo "Use this to connect your L2TP service."
echo "IP: $IP"
echo "username: $u"
echo "password: $p"
echo "Secretkey: $k"
echo "##################################"

# if choose 2:
elif test $x -eq 2; then
	echo "Please input an new username:"
	read u
	echo "Please input the password:"
	read p

# Add an new account
echo "$u  l2tp  $p  *" >> /etc/ppp/chap-secrets

echo
echo "##############"
echo "Success!"

else
echo "Error."
exit
fi
