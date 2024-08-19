#!/bin/bash

# دریافت اطلاعات حساب کاربری از کاربر
read -p "Please enter your API ID: " api_id
read -p "Please enter your API Hash: " api_hash
read -p "Please enter your phone number: " phone_number
read -p "Please enter the channel username (e.g., @channelusername): " channel_username

# ایجاد یک فایل پایتون موقت برای اجرای کد
cat << EOF > temp_script.py
from telethon import TelegramClient, events
import asyncio

api_id = "$api_id"
api_hash = "$api_hash"
phone_number = "$phone_number"
channel_username = "$channel_username"

client = TelegramClient('session_name', api_id, api_hash)

async def main():
    await client.start(phone=phone_number)
    print("Client Created and Online")

    while True:
        await client.send_message(channel_username, 'Keeping the channel active')
        await asyncio.sleep(5)

client.loop.run_until_complete(main())
EOF

# اجرای فایل پایتون
python temp_script.py

# حذف فایل پایتون موقت پس از اجرا
rm temp_script.py
