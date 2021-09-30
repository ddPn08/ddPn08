#!/bin/bash

mv /etc/selinux/config /etc/selinux/config.old
sed -e "7 s/enforcing/disabled/g" /etc/selinux/config.old > /etc/selinux/config


if [ ! -e /etc/yum.repos.d/nginx.repo ]; then
    touch /etc/yum.repos.d/nginx.repo
    cat  <<EOL >> /etc/yum.repos.d/nginx.repo
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/\$releasever/\$basearch/
gpgcheck=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOL
fi

nginx -v &> /dev/null
if [ $? -ne 0 ] ; then
    dnf install -y nginx

    rm -f /etc/nginx/nginx.conf
    touch /etc/nginx/nginx.conf
    cat  <<EOL >> /etc/nginx/nginx.conf

user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}

stream {
    include /etc/nginx/conf.d/stream/*.conf;
}

EOL

    if [ ! -e /etc/nginx/conf.d/stream/ ]; then
        mkdir /etc/nginx/conf.d/stream/
        touch /etc/nginx/conf.d/stream/minecraft.conf
    fi

    cat  <<EOL >> /etc/nginx/conf.d/stream/minecraft.conf
#
#  minecraft.conf
#

upstream MC_BE {
    server 202.213.147.59:19132;
}

server {
    listen      19132  udp;
    proxy_protocol on;

    proxy_pass MC_BE;
}


upstream MC_Java {
    server 202.213.147.59:25565;
}

server {
    listen      25565;
    proxy_protocol on;

    proxy_pass MC_Java;
}

# minecraft.conf

EOL
fi

