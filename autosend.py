from telethon import TelegramClient, events
import asyncio

# دریافت اطلاعات حساب کاربری از کاربر
api_id = input("Please enter your API ID: ")
api_hash = input("Please enter your API Hash: ")
phone_number = input("Please enter your phone number: ")

# ایجاد یک کلاینت تلگرام
client = TelegramClient('session_name', api_id, api_hash)

# متغیر برای نگه داشتن وضعیت فعال یا غیر فعال بودن بات
bot_active = True

async def main():
    # اتصال به حساب کاربری
    await client.start(phone=phone_number)
    print("Client Created and Online")

    # هندلر برای دریافت پیام‌ها
    @client.on(events.NewMessage)
    async def handler(event):
        global bot_active
        
        # چک می‌کند که پیام از یک شخص باشد (نه از کانال یا گروه)
        if event.is_private:
            message_text = event.message.message.lower()

            # بررسی دستورات برای شروع و توقف بات
            if message_text == '.start':
                bot_active = True
                await event.respond("Bot has been activated.")
            elif message_text == '.stop':
                bot_active = False
                await event.respond("Bot has been deactivated.")
            # اگر بات فعال است، پاسخ ارسال کند
            elif bot_active:
                await event.respond('.صبور باشید در اسرع وقت پاسخگو هستم')

    # نگه داشتن کلاینت آنلاین
    await client.run_until_disconnected()

# اجرای برنامه
client.loop.run_until_complete(main())
