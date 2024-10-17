#!/bin/bash

# Prompt the user for required information
read -p "Please enter your API ID: " api_id
read -p "Please enter your API Hash: " api_hash
read -p "Please enter your phone number connected to Telegram: " phone_number
read -p "Please enter the admin's Telegram ID: " admin_id

# Check if Python3 is installed, and install it if not
if ! command -v python3 &> /dev/null
then
    echo "Python3 is not installed. Installing Python3..."
    sudo apt-get update
    sudo apt-get install python3 -y
fi

# Check if pip is installed, and install it if not
if ! command -v pip &> /dev/null
then
    echo "pip is not installed. Installing pip..."
    sudo apt-get install python3-pip -y
fi

# Check if the 'telethon' library is installed, and install it if not
pip show telethon &> /dev/null
if [ $? -ne 0 ]; then
    echo "The telethon library is not installed. Installing telethon..."
    pip install telethon
fi

# Create the Python file and insert the Python code
echo "Creating the Python script..."
cat > TelegramAutoreply.py << EOL
from telethon import TelegramClient, events

# Information required to connect to the Telegram account
api_id = '$api_id'
api_hash = '$api_hash'
phone_number = '$phone_number'
admin_id = '$admin_id'

# Create the Telegram client with user-supplied information
client = TelegramClient('khalil', int(api_id), api_hash)

# Variable to enable or disable auto-reply
auto_reply_enabled = False
# Default auto-reply message
auto_reply_message = "Please be patient. I will reply to you in the evening."

# Function to handle messages and enable/disable auto-reply
@client.on(events.NewMessage(incoming=True))
async def my_event_handler(event):
    global auto_reply_enabled, auto_reply_message
    sender = await event.get_sender()
    sender_id = sender.id

    # Check if the message is from a private chat and not a group or channel
    if event.is_private:
        # Only the admin can send commands
        if sender_id == int(admin_id):
            if event.raw_text == ".start":
                auto_reply_enabled = True
                await event.respond("Auto-reply has been activated.")
            elif event.raw_text == ".stop":
                auto_reply_enabled = False
                await event.respond("Auto-reply has been deactivated.")
            elif event.raw_text.startswith(".edit "):
                new_message = event.raw_text[6:].strip()
                if new_message:
                    auto_reply_message = new_message
                    await event.respond(f"Auto-reply message updated to: {auto_reply_message}")
                else:
                    await event.respond("Please provide a valid message after the .edit command.")
        # Send an auto-reply to private chats if auto-reply is enabled
        elif auto_reply_enabled:
            await event.respond(auto_reply_message)

# Start the Telegram client and handle events
client.start()  # No need for phone_number
client.run_until_disconnected()
EOL

# Notify the user that the Python file has been created
echo "Python script created successfully: TelegramAutoreply.py"

# Run the Python script
python3 TelegramAutoreply.py
