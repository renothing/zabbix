#!/bin/bash
# zabbix agentd upgrade
# fork from zabbix_agentd_install
# @author yongtianyong
# @modify hulei 2013/11/29

# run as ROOT
if [[ $UID -ne 0 ]]
then
    echo "please run as ROOT"
    exit 1
fi

predir=/usr/local
z_version=2.2.0
z_server=54.238.51.184

#complie and install zabbix agent
cd /usr/local/src/
zabbix_src_url=http://sourceforge.net/projects/zabbix/files/ZABBIX%20Latest%20Stable/${z_version}/zabbix-${z_version}.tar.gz/download
if [ ! -f zabbix-${z_version}.tar.gz ];then
	wget --content-disposition "$zabbix_src_url" 
fi
rm -rf zabbix-${z_version}
tar xf zabbix-${z_version}.tar.gz || exit 1
cd zabbix-${z_version}
./configure --prefix=${predir}/zabbix --enable-agent --with-libcurl
make && make install 
rm -r /usr/local/zabbix/etc/zabbix_agent.conf{,.d/}
#config zabbix agent
cat > ${predir}/zabbix/etc/zabbix_agentd.conf <<EOF
LogFile=/tmp/zabbix_agentd.log
Server=${z_server}
ServerActive=${z_server}
AllowRoot=1
EnableRemoteCommands=1
LogRemoteCommands=1

Include=/usr/local/zabbix/etc/zabbix_agentd.conf.d
EOF

#generate zabbix-agentd init script
cat > /etc/init.d/zabbix-agentd  <<EOF
#!/bin/sh

NAME=zabbix_agentd
DAEMON=/usr/local/zabbix/sbin/\${NAME}
DESC="Zabbix agent daemon"
PID=/tmp/\$NAME.pid

test -f \$DAEMON || exit 0

case "\$1" in
  start)
        echo "Starting \$DESC: \$NAME"
        start-stop-daemon --start --oknodo --pidfile \$PID --exec \$DAEMON && exit 0
        ;;
  stop)
        echo "Stopping \$DESC: \$NAME"
        start-stop-daemon --stop --quiet --pidfile \$PID --retry=TERM/10/KILL/5 && exit 0
        start-stop-daemon --stop --oknodo --exec \$DAEMON --name \$NAME --retry=TERM/10/KILL/5
        ;;
  restart|force-reload)
        \$0 stop
        \$0 start
        ;;
  *)
        echo "Usage: \$0 {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac

EOF
chmod 755 /etc/init.d/zabbix-agentd
update-rc.d zabbix-agentd defaults 76 21
/etc/init.d/zabbix-agentd start
