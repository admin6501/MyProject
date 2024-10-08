#!/bin/bash

# تابع برای پیدا کردن فایل لاگ دایرکت ادمین
find_log_file() {
    local log_dir="/var/log/directadmin"
    local log_file=$(find $log_dir -type f -name "*.log" | grep "errortaskq.log")
    echo $log_file
}

# پیدا کردن فایل لاگ
LOG_FILE=$(find_log_file)

# ایمیل ادمین
ADMIN_EMAIL="user@amoozeshpc65.ir"

# تابع ارسال ایمیل خوش‌آمدگویی
send_welcome_email() {
    local user_email=$1
    local username=$2
    local password=$3
    local domain=$4

    local login_url="http://$domain:2222"

    /usr/sbin/sendmail -t <<EOF
To: $user_email
Subject: خوش‌آمدید به هاستینگ ما

سلام $username،

به هاستینگ ما خوش آمدید! اطلاعات ورود شما به شرح زیر است:

نام کاربری: $username
رمز عبور: $password
آدرس ورود: $login_url

با تشکر،
تیم پشتیبانی
EOF
}

# مانیتور کردن فایل لاگ برای ایجاد حساب‌های جدید
tail -F $LOG_FILE | while read line; do
    if [[ "$line" == *"User created successfully"* ]]; then
        # استخراج اطلاعات کاربر جدید از خط لاگ
        user_email=$(echo $line | grep -oP '(?<=email: ).*?(?=,)')
        username=$(echo $line | grep -oP '(?<=username: ).*?(?=,)')
        password=$(echo $line | grep -oP '(?<=password: ).*?(?=,)')
        domain=$(echo $line | grep -oP '(?<=domain: ).*?(?=,)')
        
        # ارسال ایمیل خوش‌آمدگویی
        send_welcome_email $user_email $username $password $domain
    fi
done
