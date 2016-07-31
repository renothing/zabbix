#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# Copyright © 2016-07-31 15:20 renothing <frankdot@qq.com>
#
# Distributed under terms of the Apache license.
# -*- coding: utf-8 -*-
''' 
this is custom metainfo generator for zabbix agent
'''
import platform
import sys

def getMetainfo(*kw):
    metainfo = list(platform.uname())
    if len(kw)>1:
       args = kw[1:]
       metainfo.extend(args)
    return ' '.join(metainfo)

print getMetainfo(*sys.argv)
