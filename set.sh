#!/bin/bash

# جستجوی کل دایرکتوری‌های سرور و تنظیم دسترسی‌های فایل‌های .htaccess
find / -type f -name ".htaccess" -exec chmod 644 {} \; 2>/dev/null

echo "Permissions for all .htaccess files have been set to 644."
