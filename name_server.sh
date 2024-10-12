#!/bin/bash

# به روز رسانی آدرس های منبع
sed -i 's/http:\/\/[a-z]*.archive.ubuntu.com/http:\/\/mirror.arvancloud.ir/g' /etc/apt/sources.list
sed -i 's|http://deb.debian.org/debian|http://mirror.arvancloud.ir/debian|g' /etc/apt/sources.list

# به روز رسانی لیست بسته‌ها
apt update

# تنظیم DNS
rm -rf /etc/resolv.conf
touch /etc/resolv.conf
echo 'nameserver 10.202.10.202' >> /etc/resolv.conf
echo 'nameserver 10.202.10.102' >> /etc/resolv.conf
echo "185.199.108.133 raw.githubusercontent.com" >> /etc/hosts

# نصب بسته‌هایتان را اینجا اضافه کنید
# apt install <package_name>

# بازگشت DNS به حالت اولیه
rm -rf /etc/resolv.conf
touch /etc/resolv.conf
echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
echo 'nameserver 8.4.4.8' >> /etc/resolv.conf
