#!/bin/bash

# مسیر فایل تنظیمات دایرکت ادمین
DIRECTADMIN_CONF="/usr/local/directadmin/conf/directadmin.conf"

# بررسی وجود فایل تنظیمات
if [ ! -f "$DIRECTADMIN_CONF" ]; then
    echo "فایل تنظیمات دایرکت ادمین یافت نشد!"
    exit 1
fi

# تغییر زبان به انگلیسی
sed -i 's/^language=.*/language=en/' "$DIRECTADMIN_CONF"

# راه‌اندازی مجدد دایرکت ادمین
service directadmin restart

echo "زبان دایرکت ادمین با موفقیت به انگلیسی تغییر یافت."
