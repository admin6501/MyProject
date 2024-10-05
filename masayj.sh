#!/bin/bash

# درخواست اطلاعات API از کاربر
read -p "لطفاً API ID خود را وارد کنید: " api_id
read -p "لطفاً API Hash خود را وارد کنید: " api_hash
read -p "لطفاً شماره تلفن خود را وارد کنید: " phone_number

# ایجاد فایل پایتون با اطلاعات وارد شده
cat <<EOL > auto_reply.py
from telethon import TelegramClient, events

# اطلاعات API
api_id = '$api_id'
api_hash = '$api_hash'
phone_number = '$phone_number'

# ایجاد کلاینت تلگرام
client = TelegramClient('session_name', api_id, api_hash)

# متغیر برای فعال یا غیرفعال کردن پاسخ خودکار
auto_reply_enabled = False

# مجموعه‌ای برای ذخیره شناسه پیام‌هایی که به آن‌ها پاسخ داده شده است
replied_messages = set()

@client.on(events.NewMessage(incoming=True))
async def handle_new_message(event):
    global auto_reply_enabled
    if auto_reply_enabled and event.is_private and event.id not in replied_messages:
        await event.reply('سلام، در اسرع وقت پاسخگوی شما خواهم بود.')
        replied_messages.add(event.id)

@client.on(events.NewMessage(pattern='/start'))
async def start(event):
    global auto_reply_enabled
    auto_reply_enabled = True
    await event.reply('پاسخ خودکار فعال شد.')

@client.on(events.NewMessage(pattern='/stop'))
async def stop(event):
    global auto_reply_enabled
    auto_reply_enabled = False
    await event.reply('پاسخ خودکار غیرفعال شد.')

async def main():
    await client.start(phone_number)
    print("Client Created")
    await client.run_until_disconnected()

if __name__ == '__main__':
    import asyncio
    asyncio.run(main())
EOL

# اجرای اسکریپت پایتون
python3 auto_reply.py
