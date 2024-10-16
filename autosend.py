from telethon import TelegramClient, events
import asyncio
import logging

# تنظیمات log
logging.basicConfig(level=logging.INFO)

# دریافت اطلاعات حساب کاربری از کاربر
api_id = input("Please enter your API ID: ")
api_hash = input("Please enter your API Hash: ")
phone_number = input("Please enter your phone number: ")

# ایجاد یک کلاینت تلگرام
client = TelegramClient('session_name', api_id, api_hash)

# متغیر برای نگه داشتن وضعیت فعال یا غیر فعال بودن بات
bot_active = True

# متغیر برای نگه داشتن شناسه کاربر
authorized_user_id = None

async def main():
    global authorized_user_id
    try:
        # اتصال به حساب کاربری
        await client.start(phone=phone_number)
        logging.info("Client Created and Online")

        # دریافت شناسه کاربر
        authorized_user = await client.get_me()
        authorized_user_id = authorized_user.id
        logging.info(f"Authorized user ID: {authorized_user_id}")

        # هندلر برای دریافت پیام‌ها
        @client.on(events.NewMessage)
        async def handler(event):
            global bot_active

            # چک می‌کند که پیام از یک شخص باشد (نه از کانال یا گروه) و از کاربر مجاز ارسال شده باشد
            if event.is_private and event.sender_id == authorized_user_id:
                message_text = event.message.message.lower()
                # بررسی دستورات برای شروع و توقف بات
                if message_text == '.start':
                    bot_active = True
                    await event.respond("Bot has been activated.")
                    logging.info("Bot activated")
                elif message_text == '.stop':
                    bot_active = False
                    await event.respond("Bot has been deactivated.")
                    logging.info("Bot deactivated")
                # سایر پیام‌ها را نادیده بگیرد
                else:
                    logging.info("Command ignored")

        # نگه داشتن کلاینت آنلاین
        await client.run_until_disconnected()
    except Exception as e:
        logging.error(f"An error occurred: {e}")

# اجرای برنامه
client.loop.run_until_complete(main())
