#!/bin/bash

sudo /Users/xuefeihu/software/openresty/nginx/sbin/nginx -t -q -c /Users/xuefeihu/hugege/code-sublime/zhyuge/config/nginx.conf
sudo /Users/xuefeihu/software/openresty/nginx/sbin/nginx -c /Users/xuefeihu/hugege/code-sublime/zhyuge/config/nginx.conf -p /Users/xuefeihu/hugege/code-sublime/zhyuge/ -s stop

echo "openresty stop"
echo -e "#####################################################\n\n"
tail -f /Users/xuefeihu/hugege/code-sublime/zhyuge/logs/error.log
