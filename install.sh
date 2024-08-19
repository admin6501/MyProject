#!/bin/bash

pip install telethon

read -p "لطفاً شماره تلفن خود را وارد کنید (شامل کد کشور): " phone_number
read -p "لطفاً نام کانال منبع را وارد کنید (مثلاً @justV2config): " source_channel
read -p "لطفاً نام کانال مقصد را وارد کنید (مثلاً @freeConfigv2r): " destination_channel
read -p "لطفاً api_id خود را وارد کنید: " api_id
read -p "لطفاً api_hash خود را وارد کنید: " api_hash

python - <<EOF
from telethon import TelegramClient, events
import asyncio

api_id = $api_id
api_hash = '$api_hash'
phone_number = '$phone_number'
source_channel = '$source_channel'
destination_channel = '$destination_channel'

client = TelegramClient('session_name', api_id, api_hash)

async def main():
    await client.start(phone=phone_number)

    @client.on(events.NewMessage(chats=source_channel))
    async def handler(event):
        await client.send_message(destination_channel, event.message)

    print(f"در حال گوش دادن به پیام‌ها از کانال {source_channel} و ارسال به {destination_channel}...")
    await client.run_until_disconnected()

with client:
    client.loop.run_until_complete(main())
EOF
