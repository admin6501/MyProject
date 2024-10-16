#!/bin/bash

# دریافت اطلاعات حساب کاربری از کاربر
read -p "Please enter your API ID: " api_id
read -p "Please enter your API Hash: " api_hash
read -p "Please enter your phone number: " phone_number

# ایجاد یک فایل پایتون برای اجرای اسکریپت
cat <<EOF > telegram_client.py
from telethon import TelegramClient, events
import asyncio

api_id = "$api_id"
api_hash = "$api_hash"
phone_number = "$phone_number"

client = TelegramClient('session_name', api_id, api_hash)
bot_active = True

async def main():
    await client.start(phone=phone_number)
    print("Client Created and Online")

    @client.on(events.NewMessage)
    async def handler(event):
        global bot_active

        if event.is_private:
            message_text = event.message.message.lower()
            if message_text == '.start':
                bot_active = True
                await event.respond("Bot has been activated.")
            elif message_text == '.stop':
                bot_active = False
                await event.respond("Bot has been deactivated.")
            elif bot_active:
                await event.respond('صبور باشید در اسرع وقت پاسخگو هستم')

    await client.run_until_disconnected()

client.loop.run_until_complete(main())
EOF

# اجرای اسکریپت پایتون
python3 telegram_client.py
