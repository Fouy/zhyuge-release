#!/bin/bash

ps -fe | grep nginx | grep -v grep
if [ $? -ne 0 ] 
then
  sudo /Users/xuefeihu/software/openresty/nginx/sbin/nginx -t -q -c /Users/xuefeihu/hugege/code-sublime/zhyuge/config/nginx.conf 
  sudo /Users/xuefeihu/software/openresty/nginx/sbin/nginx -c /Users/xuefeihu/hugege/code-sublime/zhyuge/config/nginx.conf -p /Users/xuefeihu/hugege/code-sublime/zhyuge/
  echo "openresty start"
else
  sudo /Users/xuefeihu/software/openresty/nginx/sbin/nginx -t -q -c /Users/xuefeihu/hugege/code-sublime/zhyuge/config/nginx.conf
  sudo /Users/xuefeihu/software/openresty/nginx/sbin/nginx -c /Users/xuefeihu/hugege/code-sublime/zhyuge/config/nginx.conf -p /Users/xuefeihu/hugege/code-sublime/zhyuge/ -s reload
  echo "openresty reload"
fi
echo -e "#####################################################\n\n"
tail -f /Users/xuefeihu/hugege/code-sublime/zhyuge/logs/error.log
