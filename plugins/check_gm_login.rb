#!/usr/bin/ruby
# encoding: UTF-8
require 'rubygems'
require 'net/http'
require 'json'

def get_loc_ip()
    ip=Net::HTTP.get_response(URI("http://www.myexternalip.com/raw"))
    return ip.body
end

def get_result(url='localhost',port=80)
  res=[]
  respone=Net::HTTP.get_response(URI("http://#{url}:#{port}//alarms.json?zbx=last_login"))
  res = JSON.parse(respone.body)
  return res
end

if ARGV.length !=2
  STDOUT.puts <<-EOF
    usage:
    script [ip] port]
  EOF
else
  if ARGV[0].empty?
      ip='127.0.0.1'
  else
      ip=ARGV[0]
  end
  if ARGV[1].empty?
      port='80'
  else
      port=ARGV[1]
  end
  result=get_result(url=ip,port=port)
  result.each do |k,v|
    x=DateTime.parse(v,utc)
    puts "#{x}"
  end
end

