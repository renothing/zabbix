#!/bin/bash
#install zabbix agent for debian/ubuntu
# @author renothing

predir=/usr/local
z_version=2.0.6
z_server=$1
Usage(){
    echo "Usage:" 1>&2
    echo "    $0 [server ip]" 1>&2
    exit 1
}

#get args
if  [ $# -eq 0 ];then
    Usage
fi

if [[ ! -n $z_server ]];then
	Usage
fi

#install requirements
if [[ `grep -E "Debian|Ubuntu" /etc/issue` ]];then
	apt-get update
	apt-get install lsb-release debconf-utils wget -y
fi
release=`lsb_release -c|awk '{print $2}'`
system=`lsb_release -i|awk '{print $3}'`
version=`lsb_release -r|awk '{print $2}'|cut -d"." -f1`
case $release in
squeeze)
	#for debian6
	apt-get install -y libssh2-1 fping libcurl3 libiksemel3 libcurl4-openssl-dev
	apt-get install -y libmysqlclient18 libmysqlclient18-dev libsnmp-dev libopenipmi-dev
	apt-get install -y gcc g++ autoconf autoconf2.13 make cmake patch;;
maverick)
	#for ubuntu 10.10
	apt-get install -y libssh2-1 fping libcurl3 libiksemel3 libcurl4-openssl-dev
	apt-get install -y libmysqlclient-dev libmysqlclient-dev libsnmp-dev libsnmp15 openipmi libopenipmi-dev
	apt-get install -y gcc g++ autoconf autoconf2.13 make cmake patch;;
natty)
	#for ubuntu 11.04
	apt-get install -y libssh2-1 fping libcurl3 libiksemel3 libcurl4-openssl-dev
	apt-get install -y libmysqlclient16 libmysqlclient-dev libsnmp-dev libopenipmi-dev
	apt-get install -y gcc g++ autoconf autoconf2.13 make cmake patch;;
precise)
	#for ubuntu 12.04
	apt-get install -y libssh2-1 fping libcurl3 libiksemel3 libcurl4-openssl-dev
	apt-get install -y libmysqlclient18 libmysqlclient-dev libsnmp-dev libopenipmi-dev
	apt-get install -y gcc g++ autoconf autoconf2.13 make cmake patch;;
esac

#add user
groupadd zabbix
useradd -g zabbix zabbix
#complie and install zabbix agent
mkdir -p /var/src/
cd /var/src
if [ ! -f zabbix-${z_version}.tar.gz ];then
	wget --content-disposition http://sourceforge.net/projects/zabbix/files/ZABBIX%20Latest%20Stable/${z_version}/zabbix-${z_version}.tar.gz/download
fi
rm -rf zabbix-${z_version}
tar xf zabbix-${z_version}.tar.gz
cd zabbix-${z_version}
./configure --prefix=${predir}/zabbix --enable-agent --enable-ipv6 --with-ssh2 --with-libcurl --with-openipmi
make && make install
#config zabbix agent
cat > ${predir}/zabbix/etc/zabbix_agentd.conf <<EOF
LogFile=/tmp/zabbix_agentd.log
Server=${z_server}
ServerActive=${z_server}
EnableRemoteCommands=1
AllowRoot=1
EnableRemoteCommands=1
LogRemoteCommands=1
EOF
#generate agent init script
cat > /etc/init.d/zabbix-agent  <<EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:          zabbix_agentd
# Required-Start:    \$local_fs \$remote_fs \$network \$syslog
# Required-Stop:     \$local_fs \$remote_fs \$network \$syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the zabbix_agentd daemon
# Description:       starts zabbix_agentd using start-stop-daemon
### END INIT INFO
#
# Zabbix agent start/stop script.
#
# Copyright (C) 2000-2012 Zabbix SIA

NAME=zabbix_agentd
DAEMON=/usr/local/zabbix/sbin/\${NAME}
DESC="Zabbix agent daemon"
PID=/tmp/\$NAME.pid

test -f \$DAEMON || exit 0

case "\$1" in
  start)
	echo "Starting \$DESC: \$NAME"
	start-stop-daemon --start --oknodo --pidfile \$PID --exec \$DAEMON
	;;
  stop)
	echo "Stopping \$DESC: \$NAME"
	start-stop-daemon --stop --quiet --pidfile \$PID --retry=TERM/10/KILL/5 && return 0
	start-stop-daemon --stop --oknodo --exec \$DAEMON --name \$NAME --retry=TERM/10/KILL/5
	;;
  restart|force-reload)
	\$0 stop
	\$0 start
	;;
  *)
	N=/etc/init.d/\$NAME
	echo "Usage: \$N {start|stop|restart|force-reload}" >&2
	exit 1
	;;
esac

exit 0
EOF
chmod 755 /etc/init.d/zabbix-agent
update-rc.d zabbix-agent defaults 76 21
/etc/init.d/zabbix-agent start

#allow zabbix server connections
iptables -t filter -A INPUT -p tcp -s ${z_server} --dport 10050 -j ACCEPT

