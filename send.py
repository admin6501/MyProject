from telethon import TelegramClient, events

# اطلاعات API
api_id = 'API_ID_شما'
api_hash = 'API_HASH_شما'
phone_number = 'شماره_موبایل_شما'

# ایجاد کلاینت تلگرام
client = TelegramClient('session_name', api_id, api_hash)

# مجموعه‌ای برای ذخیره شناسه‌های چت که پیام خوش‌آمدگویی دریافت کرده‌اند
sent_messages = set()

async def main():
    # اتصال به تلگرام
    await client.start(phone=phone_number)
    print("Connected to Telegram")

    # ارسال پیام خوش‌آمدگویی
    @client.on(events.NewMessage)
    async def handler(event):
        sender = await event.get_sender()
        if sender.is_self:
            return

        # بررسی نوع چت و ارسال پیام خوش‌آمدگویی فقط یک بار
        if event.is_private and event.chat_id not in sent_messages:
            await event.reply('سلام! بعد از آنلاین شدن پاسخگوی شما خواهم بود.')
            sent_messages.add(event.chat_id)

    # اجرای کلاینت
    await client.run_until_disconnected()

# اجرای اسکریپت
with client:
    client.loop.run_until_complete(main())
