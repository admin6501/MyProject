#!/bin/bash

while true; do
    clear
    echo "=============================="
    echo "      ICMP CONTROL MENU       "
    echo "=============================="
    echo "1) مسدود کردن ICMP (بستن پینگ)"
    echo "2) باز کردن ICMP (فعال کردن پینگ)"
    echo "3) خروج"
    echo "------------------------------"
    read -p "یک گزینه را انتخاب کنید: " opt

    case $opt in
        1)
            echo "[+] در حال مسدود کردن ICMP ..."
            echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_all
            sed -i '/icmp_echo_ignore_all/d' /etc/sysctl.conf
            echo "net.ipv4.icmp_echo_ignore_all = 1" >> /etc/sysctl.conf
            sysctl -p >/dev/null
            echo "[✔] پینگ مسدود شد."
            read -p "برای ادامه Enter را بزنید..."
        ;;
        2)
            echo "[+] در حال باز کردن ICMP ..."
            echo "0" > /proc/sys/net/ipv4/icmp_echo_ignore_all
            sed -i '/icmp_echo_ignore_all/d' /etc/sysctl.conf
            echo "net.ipv4.icmp_echo_ignore_all = 0" >> /etc/sysctl.conf
            sysctl -p >/dev/null
            echo "[✔] پینگ فعال شد."
            read -p "برای ادامه Enter را بزنید..."
        ;;
        3)
            echo "خروج..."
            exit 0
        ;;
        *)
            echo "گزینه اشتباه است!"
            sleep 1
        ;;
    esac
done
