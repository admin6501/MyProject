#!/bin/bash

# متغیرها
IONCUBE_URL="https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz"
IONCUBE_DIR="/usr/local/ioncube"
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
PHP_INI_DIR=$(php -i | grep "Loaded Configuration File" | awk '{print $5}')

# دانلود ionCube Loader
echo "دانلود ionCube Loader..."
wget -q $IONCUBE_URL -O /tmp/ioncube_loaders.tar.gz

# استخراج فایل‌ها
echo "استخراج فایل‌ها..."
mkdir -p $IONCUBE_DIR
tar -zxvf /tmp/ioncube_loaders.tar.gz -C $IONCUBE_DIR

# انتقال فایل‌ها به دایرکتوری مناسب
echo "انتقال فایل‌ها..."
cp $IONCUBE_DIR/ioncube/ioncube_loader_lin_${PHP_VERSION}.so $(php -i | grep extension_dir | awk '{print $3}')

# پیکربندی PHP
echo "پیکربندی PHP..."
echo "zend_extension=$(php -i | grep extension_dir | awk '{print $3}')/ioncube_loader_lin_${PHP_VERSION}.so" >> $PHP_INI_DIR

# راه‌اندازی مجدد وب سرور
echo "راه‌اندازی مجدد وب سرور..."
if [ -x "$(command -v systemctl)" ]; then
    systemctl restart apache2 || systemctl restart nginx
else
    service apache2 restart || service nginx restart
fi

# پاکسازی فایل‌های موقت
echo "پاکسازی فایل‌های موقت..."
rm -rf /tmp/ioncube_loaders.tar.gz $IONCUBE_DIR

echo "نصب ionCube Loader با موفقیت انجام شد!"
