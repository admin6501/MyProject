#!/bin/bash
# نصب کتابخانه‌های مورد نیاز
pip install telethon pytz

# ایجاد فایل پایتون
cat <<EOF > telegram_profile_update.py
from telethon import TelegramClient, events
import asyncio
from datetime import datetime
import pytz
from telethon.tl.functions.account import UpdateProfileRequest

# دریافت اطلاعات حساب کاربری از کاربر
api_id = input("Please enter your API ID: ")
api_hash = input("Please enter your API Hash: ")
phone_number = input("Please enter your phone number: ")

# ایجاد یک کلاینت تلگرام
client = TelegramClient('session_name', api_id, api_hash)

async def update_profile_name():
    while True:
        # دریافت زمان فعلی به وقت ایران
        iran_tz = pytz.timezone('Asia/Tehran')
        current_time = datetime.now(iran_tz).strftime('%H:%M')

        # به‌روزرسانی نام پروفایل با زمان آنلاین
        await client(UpdateProfileRequest(first_name=current_time))
        await asyncio.sleep(1)  # هر ثانیه یکبار به‌روزرسانی می‌کند

async def main():
    # اتصال به حساب کاربری
    await client.start(phone=phone_number)
    print("Client Created and Online")

    # شروع به‌روزرسانی نام پروفایل
    await update_profile_name()

# اجرای برنامه
client.loop.run_until_complete(main())
EOF

# اجرای فایل پایتون با استفاده از nohup
nohup python3 telegram_profile_update.py &
