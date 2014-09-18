#!/usr/bin/python
# encoding: UTF-8
import MySQLdb

try:
    conn=MySQLdb.connect(host='localhost',user='mysql_backuper',passwd='root',port=3306)
    cur=conn.cursor()
    cur.execute('show databases;')
    cur.close()
    conn.close()
except MySQLdb.Error,e:
    print "Mysql Error %d: %s" % (e.args[0], e.args[1])
