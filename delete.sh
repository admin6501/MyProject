#!/bin/bash

# فایل کرانجاب‌ها را در یک متغیر ذخیره می‌کنیم
CRON_FILE="/etc/crontab"

# بررسی و حذف کرانجاب‌های مربوط به عملیات هدیه حجم و زمان
grep -v "هدیه حجم" $CRON_FILE | grep -v "هدیه زمان" > /tmp/crontab.tmp

# جایگزینی فایل کرانجاب‌ها با فایل موقت
mv /tmp/crontab.tmp $CRON_FILE

# بارگذاری مجدد کرانجاب‌ها
service cron reload

echo "کرانجاب‌های مربوط به عملیات هدیه حجم و زمان حذف شدند."
