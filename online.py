from telethon import TelegramClient, events
import asyncio

# دریافت اطلاعات حساب کاربری از کاربر
api_id = input("Please enter your API ID: ")
api_hash = input("Please enter your API Hash: ")
phone_number = input("Please enter your phone number: ")
channel_username = input("Please enter the channel username (e.g., @channelusername): ")

# ایجاد یک کلاینت تلگرام
client = TelegramClient('session_name', api_id, api_hash)

async def main():
    # اتصال به حساب کاربری
    await client.start(phone=phone_number)
    print("Client Created and Online")

    # نگه داشتن کلاینت آنلاین با ارسال پیام به کانال مشخص شده
    while True:
        await client.send_message(channel_username, 'Keeping the channel active')
        await asyncio.sleep(5)  # هر 5 ثانیه یکبار پیام ارسال می‌کند

# اجرای برنامه
client.loop.run_until_complete(main())
