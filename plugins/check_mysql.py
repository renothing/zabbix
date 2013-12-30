#!/usr/bin/python
# -*- coding: utf-8 -*-
import sys
import MySQLdb as mdb

def usage(args):
    print """
 mysql monitor script for zabbix
 Author: renoting <renoting@techyou.net>

 %s [host=localhost] [port=3306] [type=master|slave|var] user=user passwd=mysqlpass key=Queries

 #before use it, run 'GRANT REPLICATION CLIENT ON *.* TO 'user'@'host' IDENTIFIED BY 'pass' on your mysql host
 """ %(args)
    sys.exit(1)

def getargs(args):
    argv={}
    args.pop(0)
    for v in args:
        k,v = v.split('=')
        argv[k] = v
    return argv

def mysqlstatus(**args):
    opts = {'host':'localhost','user':'root','port':3306,'passwd':'','key':'Queries'}
    opts =dict(opts,**args)
    sql = {
        'master': "SHOW MASTER STATUS;",
        'slave': "SHOW SLAVE STATUS;",
        'var': "SHOW GLOBAL VARIABLES;",
        None: "SHOW GLOBAL STATUS;",
    }
    try:
        conn = mdb.connect(host=opts['host'],user=opts['user'],port=opts['port'],passwd=opts['passwd'])
        cur  = conn.cursor(cursorclass=mdb.cursors.DictCursor)
        try:
            cur.execute(sql.get(opts['type'],"SHOW GLOBAL STATUS;"))
        except KeyError,TypeError:
            cur.execute(sql.get(None))
        rows = cur.fetchall()
        if len(rows) == 1: 
            ver = rows[0]
        else:
            ver =[]
            for item in rows: 
                item = item.values()
                item.reverse();ver.append(item)
            ver = dict(ver)
        ver['ping']= conn.ping() or True
        if opts['key'] in ver: return ver[opts['key']]
    except mdb.Error, e:
        print "Error %d: %s" % (e.args[0],e.args[1])
        usage(sys.argv[0])

    else:
        conn.close()

if len(sys.argv) < 4:
    usage(sys.argv[0])
else:
    parameter = getargs(sys.argv)
    print mysqlstatus(**parameter)
