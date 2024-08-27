#!/bin/bash

# دریافت توکن ربات و چت آیدی ادمین
read -p "Enter your bot token: " BOT_TOKEN
read -p "Enter admin chat ID: " ADMIN_CHAT_ID
read -p "Enter your domain (e.g., https://yourdomain.com): " DOMAIN

# URL پایه برای API تلگرام
BASE_URL="https://api.telegram.org/bot$BOT_TOKEN"

# ایجاد دایرکتوری برای ربات
mkdir -p ~/telegram_bot

# تنظیم وب‌هوک
WEBHOOK_URL="$DOMAIN/webhook"
curl -s -X POST "$BASE_URL/setWebhook" -d url="$WEBHOOK_URL"

# تابع ارسال پیام
send_message() {
    local chat_id=$1
    local text=$2
    curl -s -X POST "$BASE_URL/sendMessage" -d chat_id="$chat_id" -d text="$text" -d parse_mode="HTML"
}

# تابع ایجاد دکمه شیشه‌ای
create_button() {
    local text=$1
    local callback_data=$2
    echo "{\"text\":\"$text\",\"callback_data\":\"$callback_data\"}"
}

# تابع ایجاد منو
create_menu()
