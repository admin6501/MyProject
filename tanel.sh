#!/bin/bash

# تابع نمایش گزینه‌های روش تانلینگ
function show_menu() {
    echo "روش تانلینگ را انتخاب کنید:"
    echo "1. تانل IP به IP با استفاده از IPTables"
    echo "2. فوروارد کردن پورت به پورت با استفاده از IPTables"
    echo "3. فوروارد کردن پورت با استفاده از SSH"
    echo "4. فوروارد NAT با استفاده از IPTables"
    echo "5. خروج"
}

# تابع برای تانل IP به IP با استفاده از IPTables
function ip_to_ip_tunneling() {
    echo "آدرس IP محلی را وارد کنید:"
    read local_ip
    echo "آدرس IP مقصد (ریموت) را وارد کنید:"
    read remote_ip
    
    echo "در حال تنظیم تانل IP به IP با IPTables..."
    sudo iptables -t nat -A PREROUTING -d $local_ip -j DNAT --to-destination $remote_ip
    sudo iptables -t nat -A POSTROUTING -j MASQUERADE
    echo "تانل IP به IP تنظیم شد."
}

# تابع برای فوروارد کردن پورت به پورت با استفاده از IPTables
function port_to_port_forwarding() {
    echo "آدرس IP محلی را وارد کنید:"
    read local_ip
    echo "آدرس IP مقصد (ریموت) را وارد کنید:"
    read remote_ip
    echo "شماره پورت محلی را برای فوروارد کردن وارد کنید:"
    read local_port
    echo "شماره پورت ریموت را وارد کنید:"
    read remote_port
    
    echo "در حال تنظیم فوروارد پورت به پورت با IPTables..."
    sudo iptables -t nat -A PREROUTING -d $local_ip -p tcp --dport $local_port -j DNAT --to-destination $remote_ip:$remote_port
    sudo iptables -t nat -A POSTROUTING -j MASQUERADE
    echo "فوروارد پورت به پورت تنظیم شد."
}

# تابع برای فوروارد کردن پورت با استفاده از SSH
function ssh_port_forwarding() {
    echo "آدرس IP مقصد (ریموت) را وارد کنید:"
    read remote_ip
    echo "شماره پورت ریموت (مثلاً 22 برای SSH) را وارد کنید:"
    read remote_port
    echo "پورت محلی برای بایند کردن ترافیک را وارد کنید (مثلاً 8080):"
    read local_port
    
    echo "در حال تنظیم فوروارد پورت با SSH..."
    ssh -N -L $local_port:localhost:$remote_port $remote_ip &
    
    if [ $? -eq 0 ]; then
        echo "فوروارد پورت با SSH روی پورت محلی $local_port تنظیم شد."
    else
        echo "خطایی در تنظیم فوروارد پورت با SSH رخ داد."
    fi
}

# تابع برای فوروارد NAT با استفاده از IPTables
function nat_forwarding() {
    echo "آدرس IP محلی را وارد کنید:"
    read local_ip
    echo "آدرس IP مقصد (ریموت) را وارد کنید:"
    read remote_ip
    echo "پورتی که می‌خواهید فوروارد کنید را وارد کنید:"
    read forward_port
    
    echo "در حال تنظیم فوروارد NAT با IPTables..."
    sudo iptables -t nat -A PREROUTING -p tcp --dport $forward_port -d $local_ip -j DNAT --to-destination $remote_ip:$forward_port
    sudo iptables -t nat -A POSTROUTING -j MASQUERADE
    echo "فوروارد NAT تنظیم شد."
}

# حلقه اصلی
while true; do
    show_menu
    read -p "لطفاً یک گزینه را انتخاب کنید (1-5): " choice

    case $choice in
        1)
            ip_to_ip_tunneling
            ;;
        2)
            port_to_port_forwarding
            ;;
        3)
            ssh_port_forwarding
            ;;
        4)
            nat_forwarding
            ;;
        5)
            echo "خروج از اسکریپت."
            exit 0
            ;;
        *)
            echo "گزینه نامعتبر است، لطفاً دوباره انتخاب کنید."
            ;;
    esac
done
