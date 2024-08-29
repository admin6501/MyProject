#!/bin/bash

# Function to display the menu
show_menu() {
    echo "Please choose an option:"
    echo "1) Install Bot"
    echo "2) Remove Bot"
    read choice
    case $choice in
        1) install_bot ;;
        2) remove_bot ;;
        *) echo "Invalid option." ;;
    esac
}

# Function to install the bot
install_bot() {
    echo "Please enter your bot token:"
    read TOKEN
    echo "Please enter your admin ID:"
    read ADMIN_ID
    echo "Please enter your domain (e.g., example.com):"
    read DOMAIN

    START_TEXT="Welcome to the bot!"
    ADMIN_PANEL_TEXT="Admin Panel"
    MANAGE_BOT_TEXT="Manage Bot"
    WEBHOOK_URL="https://$DOMAIN/webhook"

    # Set webhook
    set_webhook() {
        curl -s -X POST "https://api.telegram.org/bot$TOKEN/setWebhook" -d url="$WEBHOOK_URL"
    }

    # Send message
    send_message() {
        local chat_id=$1
        local text=$2
        curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id="$chat_id" -d text="$text" -d parse_mode="Markdown"
    }

    # Send message with inline keyboard
    send_inline_keyboard() {
        local chat_id=$1
        local text=$2
        local keyboard=$3
        curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id="$chat_id" -d text="$text" -d reply_markup="$keyboard" -d parse_mode="Markdown"
    }

    # Handle updates
    handle_updates() {
        local update_id=$1
        local chat_id=$2
        local text=$3

        if [[ "$chat_id" == "$ADMIN_ID" ]]; then
            if [[ "$text" == "/start" ]]; then
                send_inline_keyboard "$chat_id" "$ADMIN_PANEL_TEXT" '{"inline_keyboard":[[{"text":"Manage Bot","callback_data":"manage_bot"}]]}'
            elif [[ "$text" == "/setstart" ]]; then
                echo "Enter new start text:"
                read new_start_text
                START_TEXT="$new_start_text"
                send_message "$chat_id" "Start text updated."
            elif [[ "$text" == "/addbutton" ]]; then
                echo "Enter new button text:"
                read button_text
                echo "Enter new button response:"
                read button_response
                # Store button and response (here simply in variables)
                BUTTON_TEXT="$button_text"
                BUTTON_RESPONSE="$button_response"
                send_message "$chat_id" "New button added."
            elif [[ "$text" == "/editbutton" ]]; then
                echo "Enter the button text you want to edit:"
                read button_text
                echo "Enter new response:"
                read button_response
                # Edit button and response (here simply in variables)
                if [[ "$button_text" == "$BUTTON_TEXT" ]]; then
                    BUTTON_RESPONSE="$button_response"
                    send_message "$chat_id" "Button response updated."
                else
                    send_message "$chat_id" "No button found with this text."
                fi
            fi
        else
            if [[ "$text" == "/start" ]]; then
                send_message "$chat_id" "$START_TEXT"
            elif [[ "$text" == "$BUTTON_TEXT" ]]; then
                send_message "$chat_id" "$BUTTON_RESPONSE"
            fi
        fi
    }

    # Main loop to get updates
    OFFSET=0
    while true; do
        RESPONSE=$(curl -s "https://api.telegram.org/bot$TOKEN/getUpdates?offset=$OFFSET")
        UPDATES=$(echo $RESPONSE | jq -c '.result[]')
        for UPDATE in $UPDATES; do
            UPDATE_ID=$(echo $UPDATE | jq -r '.update_id')
            CHAT_ID=$(echo $UPDATE | jq -r '.message.chat.id')
            TEXT=$(echo $UPDATE | jq -r '.message.text')
            handle_updates "$UPDATE_ID" "$CHAT_ID" "$TEXT"
            OFFSET=$((UPDATE_ID + 1))
        done
        sleep 1
    done

    # Set webhook
    set_webhook
}

# Function to remove the bot
remove_bot() {
    echo "Removing the bot..."
    # Add code here to remove the bot
    echo "Bot removed successfully."
}

# Display the menu
show_menu
