#!/bin/bash
#install zabbix agent for debian/centos
# @author renothing

predir=/usr/local
z_version=2.0.7
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
yum install -y gcc gcc-c++ autoconf autoconf213 cmake patch
yum install -y libssh2 libssh2-devel fping curl-devel iksemel-devel iksemel-utils Percona-Server-shared-compat net-snmp-libs net-snmp-devel
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
./configure --prefix=${predir}/zabbix --enable-agent --enable-ipv6 --with-mysql --with-net-snmp --with-libcurl --with-openipmi
make && make install
#config zabbix agent
cat > ${predir}/zabbix/etc/zabbix_agentd.conf <<EOF
LogFile=/tmp/zabbix_agentd.log
Server=${z_server}
ServerActive=${z_server}
#ListenIP=0.0.0.0
EnableRemoteCommands=1
AllowRoot=1
EnableRemoteCommands=1
LogRemoteCommands=1
EOF
#generate init script
cat > /etc/init.d/zabbix-agent  <<EOF
#!/bin/bash
#
#       /etc/rc.d/init.d/zabbix_agentd
#
# Starts the zabbix_agentd daemon
#
# chkconfig: 2345 95 5
# description: Zabbix Monitoring Agent
# processname: zabbix_agentd
# pidfile: /tmp/zabbix_agentd.pid

# Modified for Zabbix 2.0.x
# May 2012, Zabbix SIA

# Source function library.

. /etc/init.d/functions

RETVAL=0
prog="Zabbix Agent"
ZABBIX_BIN="/usr/local/zabbix/sbin/zabbix_agentd"

if [ ! -x \${ZABBIX_BIN} ] ; then
        echo -n "\${ZABBIX_BIN} not installed! "
        # Tell the user this has skipped
        exit 5
fi

start() {
        echo -n \$"Starting \$prog: "
        daemon \$ZABBIX_BIN
        RETVAL=\$?
        [ \$RETVAL -eq 0 ] && touch /var/lock/subsys/zabbix_agentd
        echo
}

stop() {
        echo -n \$"Stopping \$prog: "
        killproc \$ZABBIX_BIN
        RETVAL=\$?
        [ \$RETVAL -eq 0 ] && rm -f /var/lock/subsys/zabbix_agentd
        echo
}

case "\$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  reload|restart)
        stop
        sleep 10
        start
        RETVAL=\$?
        ;;
  condrestart)
        if [ -f /var/lock/subsys/zabbix_agentd ]; then
            stop
            start
        fi
        ;;
  status)
        status \$ZABBIX_BIN
        RETVAL=\$?
        ;;
  *)
        echo \$"Usage: \$0 {condrestart|start|stop|restart|reload|status}"
        exit 1
esac

exit \$RETVAL
EOF
chmod 755 /etc/init.d/zabbix-agent
chkconfig --add zabbix-agent
/etc/init.d/zabbix-agent start

#allow zabbix server connections
iptables -t filter -A INPUT -p tcp -s ${z_server} --dport 10050 -j ACCEPT

