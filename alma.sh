#!/bin/bash

# بررسی سطح دسترسی
if [ "$EUID" -ne 0 ]; then
  echo "لطفاً این اسکریپت را با دسترسی root اجرا کنید."
  exit 1
fi

# حذف کلیدهای SSH
echo "در حال حذف کلیدهای SSH..."
rm -rf /root/.ssh/*
echo "کلیدهای SSH حذف شدند."

# فعال‌سازی ورود با پسورد
echo "فعال‌سازی ورود با پسورد برای کاربر root..."
sed -i 's/^#*\(PasswordAuthentication\) no/\1 yes/' /etc/ssh/sshd_config
sed -i 's/^#*\(PermitRootLogin\) prohibit-password/\1 yes/' /etc/ssh/sshd_config
sed -i 's/^#*\(PermitRootLogin\) no/\1 yes/' /etc/ssh/sshd_config

# راه‌اندازی مجدد سرویس SSH
echo "راه‌اندازی مجدد سرویس SSH..."
systemctl restart sshd
echo "سرویس SSH راه‌اندازی شد."

# درخواست رمز عبور جدید برای کاربر root
read -sp "لطفاً رمز عبور جدید برای کاربر root وارد کنید: " root_password
echo
read -sp "لطفاً رمز عبور را دوباره وارد کنید: " root_password_confirm
echo

if [ "$root_password" != "$root_password_confirm" ]; then
  echo "رمزهای عبور وارد شده مطابقت ندارند. لطفاً مجدداً تلاش کنید."
  exit 1
fi

# تنظیم رمز عبور جدید برای کاربر root
echo "تنظیم رمز عبور جدید برای کاربر root..."
echo "root:$root_password" | chpasswd
echo "رمز عبور جدید تنظیم شد."

echo "عملیات با موفقیت انجام شد."
