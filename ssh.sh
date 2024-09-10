#!/bin/bash

# مسیر فایل authorized_keys
AUTHORIZED_KEYS_FILE="/root/.ssh/authorized_keys"

# حذف کلیدهای SSH از فایل authorized_keys
if [ -f "$AUTHORIZED_KEYS_FILE" ]; then
    > "$AUTHORIZED_KEYS_FILE"
    echo "کلیدهای SSH از فایل $AUTHORIZED_KEYS_FILE حذف شدند."
else
    echo "فایل $AUTHORIZED_KEYS_FILE وجود ندارد."
fi

# فعال کردن ورود با پسورد برای کاربر روت
SSHD_CONFIG_FILE="/etc/ssh/sshd_config"

if grep -q "^PermitRootLogin" "$SSHD_CONFIG_FILE"; then
    sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' "$SSHD_CONFIG_FILE"
else
    echo "PermitRootLogin yes" >> "$SSHD_CONFIG_FILE"
fi

if grep -q "^PasswordAuthentication" "$SSHD_CONFIG_FILE"; then
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG_FILE"
else
    echo "PasswordAuthentication yes" >> "$SSHD_CONFIG_FILE"
fi

# راه‌اندازی مجدد سرویس SSH
systemctl restart sshd

echo "ورود با پسورد برای کاربر روت فعال شد."
