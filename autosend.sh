#!/bin/bash

# نام فایل برای ذخیره PID
PID_FILE="bot_pid.txt"

# تابع برای اجرای کد Python (کد Telethon)
run_python_script() {
  python3 - <<EOF
from telethon import TelegramClient, events
import asyncio

api_id = input("Please enter your API ID: ")
api_hash = input("Please enter your API Hash: ")
phone_number = input("Please enter your phone number: ")

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
                await event.respond('صبور باشید آنلاین شدم جواب میدم')

    await client.run_until_disconnected()

client.loop.run_until_complete(main())
EOF
}

start_bot() {
  if [ -f "$PID_FILE" ]; then
    echo "Bot is already running!"
  else
    echo "Starting bot..."
    # اجرای کد Python در پس‌زمینه
    run_python_script &
    # ذخیره PID (شناسه فرآیند) در فایل
    echo $! > "$PID_FILE"
    echo "Bot started with PID $(cat $PID_FILE)"
  fi
}

stop_bot() {
  if [ -f "$PID_FILE" ]; then
    echo "Stopping bot..."
    # توقف فرآیند در حال اجرا
    kill $(cat $PID_FILE)
    rm "$PID_FILE"
    echo "Bot stopped."
  else
    echo "Bot is not running!"
  fi
}

status_bot() {
  if [ -f "$PID_FILE" ]; then
    echo "Bot is running with PID $(cat $PID_FILE)"
  else
    echo "Bot is not running."
  fi
}

# چک کردن دستورات ورودی
case "$1" in
  start)
    start_bot
    ;;
  stop)
    stop_bot
    ;;
  status)
    status_bot
    ;;
  *)
    echo "Usage: $0 {start|stop|status}"
    exit 1
    ;;
esac
