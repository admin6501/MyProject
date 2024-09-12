<?php
$botToken = "7371315768:AAHWbQyEzZGb8NixdHde5KzOEXRb4nHUmJg";
$adminChatId = "1429423697";
$apiUrl = "https://api.telegram.org/bot$botToken/";

$update = file_get_contents("php://input");
$updateArray = json_decode($update, true);

if (isset($updateArray["message"])) {
    $chatId = $updateArray["message"]["chat"]["id"];
    $messageText = $updateArray["message"]["text"];

    // ارسال پیام به ادمین
    $adminMessage = "پیام جدید از کاربر:\n\n" . $messageText;
    file_get_contents($apiUrl . "sendMessage?chat_id=" . $adminChatId . "&text=" . urlencode($adminMessage));

    // ارسال پیام تایید به کاربر
    $userMessage = "نظر شما با موفقیت ارسال شد. متشکریم!";
    file_get_contents($apiUrl . "sendMessage?chat_id=" . $chatId . "&text=" . urlencode($userMessage));
}
?>
