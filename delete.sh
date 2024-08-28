#!/bin/bash

# دریافت اطلاعات ورود به دیتابیس از کاربر
read -p "لطفاً نام دیتابیس را وارد کنید: " DB_NAME
read -p "لطفاً نام کاربری دیتابیس را وارد کنید: " DB_USER
read -sp "لطفاً رمز عبور دیتابیس را وارد کنید: " DB_PASS
echo

# اطلاعات سرور دیتابیس
DB_HOST="localhost"

# اتصال به دیتابیس و حذف رکوردهای مربوط به هدیه حجم و زمان
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME <<EOF
DELETE FROM gifts WHERE type IN ('volume', 'time');
EOF

echo "عملیات حذف هدیه حجم و زمان با موفقیت انجام شد."
