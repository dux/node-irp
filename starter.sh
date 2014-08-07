#!/bin/sh

# crontab -e
# @reboot /bin/sh /home/deployer/apps/node-irp/starter.sh

# nginx conf
# upstream app_cdn {
#   server 127.0.0.1:4000;
# }

# server {
#   listen 80;
#   server_name cdn.trifolium.hr;

#   location / {
#     proxy_set_header X-Real-IP $remote_addr:4000;
#     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#     proxy_set_header Host $http_host;
#     proxy_set_header X-NginX-Proxy true;

#     proxy_pass http://app_cdn/;
#     proxy_redirect off;
#   }
# }

export PATH=/usr/local/bin:$PATH
forever start --spinSleepTime 2000 --minUptime 20000 --sourceDir /home/deployer/apps/node-irp app.js >> /home/deployer/apps/node-irp/logs/log.txt 2>&1
