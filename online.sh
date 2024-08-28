#!/bin/bash

# دریافت اطلاعات از کاربر
read -p "لطفاً API ID خود را وارد کنید: " API_ID
read -p "لطفاً API Hash خود را وارد کنید: " API_HASH
read -p "لطفاً شماره تلفن خود را وارد کنید: " PHONE_NUMBER
read -p "لطفاً نام کاربری کانال را وارد کنید: " CHANNEL_USERNAME
read -p "لطفاً پیام مورد نظر خود را وارد کنید: " MESSAGE

# ایجاد اسکریپت پایتون
cat << EOF > telegram_script.py
from telethon import TelegramClient, events
import asyncio

api_id = '$API_ID'
api_hash = '$API_HASH'
phone_number = '$PHONE_NUMBER'
channel_username = '$CHANNEL_USERNAME'
message = '$MESSAGE'

client = TelegramClient('session_name', api_id, api_hash)

async def main():
    await client.start(phone_number)
    me = await client.get_me()
    print(f'Logged in as {me.username} ({me.id})')

    @client.on(events.UserUpdate)
    async def handler(event):
        if event.online:
            print(f'{event.user_id} is online')
        else:
            print(f'{event.user_id} is offline')

    while True:
        await client.send_message(channel_username, message)
        await asyncio.sleep(5)

with client:
    client.loop.run_until_complete(main())
EOF

# اجرای اسکریپت پایتون
python3 telegram_script.py
