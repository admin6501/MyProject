import subprocess
import os
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Updater, CommandHandler, CallbackQueryHandler, MessageHandler, Filters, CallbackContext

# نصب پیش‌نیازها
def install_requirements():
    subprocess.check_call(["pip", "install", "python-telegram-bot"])

# Function to get user input in English
def get_user_input(prompt):
    return input(prompt)

# Get the bot token and admin ID from the user
TOKEN = get_user_input("Please enter your bot token: ")
ADMIN_ID = get_user_input("Please enter the admin's Telegram ID: ")

# متغیر برای ذخیره متن استارت
start_message = "Please choose one of the options below:"

def start(update: Update, context: CallbackContext) -> None:
    keyboard = [
        [InlineKeyboardButton("Send Feedback", callback_data='feedback')],
        [InlineKeyboardButton("Suggestions", callback_data='suggestions')],
        [InlineKeyboardButton("Complaints", callback_data='complaints')]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    update.message.reply_text(start_message, reply_markup=reply_markup)

def button(update: Update, context: CallbackContext) -> None:
    query = update.callback_query
    query.answer()
    query.edit_message_text(text=f"You selected {query.data}. Please send your message.")

def handle_message(update: Update, context: CallbackContext) -> None:
    user_id = update.message.from_user.id
    if str(user_id) == ADMIN_ID:
        update.message.reply_text('You are in the admin panel.')
    else:
        context.bot.send_message(chat_id=ADMIN_ID, text=f"New message from {user_id}: {update.message.text}")
        update.message.reply_text('Your message has been sent.')

def admin_panel(update: Update, context: CallbackContext) -> None:
    if str(update.message.from_user.id) == ADMIN_ID:
        keyboard = [
            [InlineKeyboardButton("Add Button", callback_data='add_button')],
            [InlineKeyboardButton("Remove Button", callback_data='remove_button')],
            [InlineKeyboardButton("Edit Button", callback_data='edit_button')],
            [InlineKeyboardButton("Edit Response", callback_data='edit_response')],
            [InlineKeyboardButton("Set Start Message", callback_data='set_start_message')],
            [InlineKeyboardButton("Delete Start Message", callback_data='delete_start_message')]
        ]
        reply_markup = InlineKeyboardMarkup(keyboard)
        update.message.reply_text('Admin Panel:', reply_markup=reply_markup)
    else:
        update.message.reply_text('You do not have access to the admin panel.')

def set_start_message(update: Update, context: CallbackContext) -> None:
    query = update.callback_query
    query.answer()
    query.edit_message_text(text="Please enter the new start message:")
    context.user_data['setting_start_message'] = True

def delete_start_message(update: Update, context: CallbackContext) -> None:
    global start_message
    start_message = "Please choose one of the options below:"
    update.callback_query.answer()
    update.callback_query.edit_message_text(text="Start message has been reset to default.")

def handle_text(update: Update, context: CallbackContext) -> None:
    if context.user_data.get('setting_start_message'):
        global start_message
        start_message = update.message.text
        context.user_data['setting_start_message'] = False
        update.message.reply_text('Start message has been set.')
    else:
        handle_message(update, context)

def main() -> None:
    install_requirements()
    updater = Updater(TOKEN)
    dispatcher = updater.dispatcher

    dispatcher.add_handler(CommandHandler("start", start))
    dispatcher.add_handler(CommandHandler("panel", admin_panel))
    dispatcher.add_handler(CallbackQueryHandler(button))
    dispatcher.add_handler(CallbackQueryHandler(set_start_message, pattern='set_start_message'))
    dispatcher.add_handler(CallbackQueryHandler(delete_start_message, pattern='delete_start_message'))
    dispatcher.add_handler(MessageHandler(Filters.text & ~Filters.command, handle_text))

    updater.start_polling()
    updater.idle()

if __name__ == '__main__':
    main()
