#!/bin/bash

# درخواست نام کاربری از کاربر
read -p "لطفا نام کاربری را وارد کنید: " USER

if [ "$USER" == "root" ]; then
  SSH_DIR="/root/.ssh"
else
  SSH_DIR="/home/$USER/.ssh"
fi

AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

# بررسی اینکه آیا فایل authorized_keys وجود دارد یا خیر
if [ -f "$AUTHORIZED_KEYS" ]; then
  # حذف فایل authorized_keys
  rm "$AUTHORIZED_KEYS"
  echo "کلیدهای SSH برای کاربر $USER حذف شدند."
else
  echo "فایل authorized_keys برای کاربر $USER یافت نشد."
fi
