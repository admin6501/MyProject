#!/bin/bash

# دریافت اطلاعات مورد نیاز از کاربر
read -p "لطفاً API ID خود را وارد کنید: " API_ID
read -p "لطفاً API Hash خود را وارد کنید: " API_HASH
read -p "لطفاً شماره تلفن خود را وارد کنید: " PHONE_NUMBER
read -p "لطفاً نام کاربری کانال مبدا را وارد کنید: " SOURCE_CHANNEL
read -p "لطفاً نام کاربری کانال مقصد را وارد کنید: " DEST_CHANNEL

# ایجاد اسکریپت پایتون
cat << EOF > telegram_script.py
from telethon import TelegramClient, events
import asyncio

api_id = '$API_ID'
api_hash = '$API_HASH'
phone_number = '$PHONE_NUMBER'
source_channel = '$SOURCE_CHANNEL'
dest_channel = '$DEST_CHANNEL'

client = TelegramClient('session_name', api_id, api_hash)

async def main():
    await client.start(phone_number)
    me = await client.get_me()
    print(f'Logged in as {me.username} ({me.id})')

    @client.on(events.NewMessage(chats=source_channel))
    async def handler(event):
        if 'v2ray' in event.raw_text:
            new_message = event.raw_text.replace('v2ray', '@free-config')
            await client.send_message(dest_channel, new_message)
            print(f'Message sent to {dest_channel}')

    await client.run_until_disconnected()

with client:
    client.loop.run_until_complete(main())
EOF

# اجرای اسکریپت پایتون
python3 telegram_script.py
