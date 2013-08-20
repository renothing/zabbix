#!/bin/bash
#install zabbix server for debian/ubuntu
# @author renothing

predir=/usr/local
z_version=2.0.7
z_db='zabbix'
db_user='zabbix'
db_pass=`openssl rand -base64 12`
#install requirements
apt-get install -y libssh2-1 fping libcurl3 libiksemel3 libcurl4-openssl-dev libssh2-1 libssh2-1-dev
apt-get install -y libmysqlclient18 libmysqlclient18-dev libsnmp-dev libopenipmi-dev
apt-get install -y gcc g++ autoconf autoconf2.13 make cmake patch
ps aux|grep mysqld|grep -q -v "grep"|| { echo "please install mysql server first" && exit 1;}
#add mysql init for zabbix
mysql -e "create database $z_db character set utf8 collate utf8_general_ci;"
mysql -e "grant all privileges on  $z_db.* to $db_user@localhost identified by '$db_pass';"
#add user
groupadd zabbix
useradd -g zabbix zabbix
#complie and install zabbix server
mkdir -p /var/src/
cd /var/src
if [ ! -f zabbix-${z_version}.tar.gz ];then
	wget --content-disposition http://sourceforge.net/projects/zabbix/files/ZABBIX%20Latest%20Stable/${z_version}/zabbix-${z_version}.tar.gz/download
fi
rm -rf zabbix-${z_version}
tar xf zabbix-${z_version}.tar.gz
cd zabbix-${z_version}
./configure --prefix=${predir}/zabbix --enable-server --enable-proxy --enable-agent --enable-ipv6 --with-mysql --with-ssh2 --with-net-snmp --with-libcurl --with-openipmi 
make && make install
#config zabbix agent
sed -i '/^$/d;/^#/d' > ${predir}/etc/zabbix_agentd.conf
#config zabbix server
cat > ${predir}/zabbix/etc/zabbix_server.conf <<EOF
ListenPort=10051
LogFile=/tmp/zabbix_server.log
DebugLevel=4
DBHost=localhost
DBName=${z_db}
DBUser=${db_user}
DBPassword=${db_pass}
DBSocket=/var/run/mysqld/mysqld.sock
StartPollers=5
EOF
#generate server init script
cat > /etc/init.d/zabbix-server  <<EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:          zabbix_server
# Required-Start:    \$local_fs \$remote_fs \$network \$syslog
# Required-Stop:     \$local_fs \$remote_fs \$network \$syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the zabbix_server daemon
# Description:       starts zabbix_server using start-stop-daemon
### END INIT INFO
#
# Zabbix agent start/stop script.
#
# Copyright (C) 2000-2012 Zabbix SIA

NAME=zabbix_server
DAEMON=/usr/local/zabbix/sbin/\${NAME}
DESC="Zabbix server daemon"
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
chmod 755 /etc/init.d/zabbix-server
update-rc.d zabbix-server defaults 76 21
/etc/init.d/zabbix-server start

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

iptables -t filter -A INPUT -p tcp -d ${z_server} --dport 10051 -j ACCEPT

mysql $z_db </var/src/zabbix-${z_version}/database/mysql/schema.sql
mysql $z_db </var/src/zabbix-${z_version}/database/mysql/images.sql
mysql $z_db </var/src/zabbix-${z_version}/database/mysql/data.sql

