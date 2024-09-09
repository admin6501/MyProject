#!/bin/bash

# دریافت اطلاعات مورد نیاز از کاربر
read -p "Enter your bot token: " botToken
read -p "Enter your admin ID: " adminId
read -p "Enter your domain (with SSL): " domain

# تنظیم وب‌هوک
webhookUrl="https://$domain/bot$botToken"
response=$(curl -s -X POST "https://api.telegram.org/bot$botToken/setWebhook" -d "url=$webhookUrl")

if [[ $response == *"true"* ]]; then
    echo "Webhook set successfully."
else
    echo "Failed to set webhook. Response: $response"
    exit 1
fi

# ایجاد فایل PHP با اطلاعات وارد شده
cat <<EOT > bot_script.php
<?php
\$botToken = "$botToken";
\$adminId = "$adminId";
\$apiUrl = "https://api.telegram.org/bot\$botToken/";
\$startMessageFile = "start_message.txt";

if (!file_exists(\$startMessageFile)) {
    file_put_contents(\$startMessageFile, "Welcome to the bot! Use the buttons to interact.");
}

function sendRequest(\$method, \$parameters) {
    global \$apiUrl;
    \$url = \$apiUrl . \$method;
    \$options = [
        'http' => [
            'header'  => "Content-type: application/json\r\n",
            'method'  => 'POST',
            'content' => json_encode(\$parameters),
        ],
    ];
    \$context  = stream_context_create(\$options);
    \$result = file_get_contents(\$url, false, \$context);
    return json_decode(\$result, true);
}

function sendMessage(\$chatId, \$text, \$replyMarkup = null) {
    \$parameters = [
        'chat_id' => \$chatId,
        'text' => \$text,
    ];
    if (\$replyMarkup) {
        \$parameters['reply_markup'] = \$replyMarkup;
    }
    sendRequest("sendMessage", \$parameters);
}

function handleCallbackQuery(\$callbackQuery) {
    global \$adminId;
    \$chatId = \$callbackQuery['message']['chat']['id'];
    \$data = \$callbackQuery['data'];

    if (\$chatId == \$adminId) {
        // Handle admin commands
        if (\$data == "add_button") {
            sendMessage(\$chatId, "Please send the button name:");
        } elseif (\$data == "delete_button") {
            sendMessage(\$chatId, "Please send the button name to delete:");
        } elseif (\$data == "edit_button_name") {
            sendMessage(\$chatId, "Please send the old and new button names:");
        } elseif (\$data == "edit_button_message") {
            sendMessage(\$chatId, "Please send the button name and new message:");
        } elseif (\$data == "edit_start_message") {
            sendMessage(\$chatId, "Please send the new start message:");
        }
    } else {
        // Forward user message to admin
        sendMessage(\$adminId, "User clicked: \$data");
    }
}

function handleMessage(\$message) {
    global \$adminId, \$startMessageFile;
    \$chatId = \$message['chat']['id'];
    \$text = \$message['text'];

    if (\$chatId == \$adminId) {
        // Handle admin messages
        if (\$text == "/start") {
            \$keyboard = [
                'inline_keyboard' => [
                    [['text' => 'Add Button', 'callback_data' => 'add_button']],
                    [['text' => 'Delete Button', 'callback_data' => 'delete_button']],
                    [['text' => 'Edit Button Name', 'callback_data' => 'edit_button_name']],
                    [['text' => 'Edit Button Message', 'callback_data' => 'edit_button_message']],
                    [['text' => 'Edit Start Message', 'callback_data' => 'edit_start_message']],
                ],
            ];
            sendMessage(\$chatId, "Admin Panel", json_encode(\$keyboard));
        } elseif (file_exists(\$startMessageFile) && strpos(file_get_contents(\$startMessageFile), \$text) === false) {
            file_put_contents(\$startMessageFile, \$text);
            sendMessage(\$chatId, "Start message updated.");
        }
    } else {
        // Handle user messages
        if (file_exists(\$startMessageFile)) {
            \$startMessage = file_get_contents(\$startMessageFile);
            sendMessage(\$chatId, \$startMessage);
        } else {
            sendMessage(\$chatId, "Hello! Please use the buttons to interact.");
        }
    }
}

\$content = file_get_contents("php://input");
\$update = json_decode(\$content, true);

if (isset(\$update['message'])) {
    handleMessage(\$update['message']);
} elseif (isset(\$update['callback_query'])) {
    handleCallbackQuery(\$update['callback_query']);
}
?>
EOT

# اجرای فایل PHP
php bot_script.php
