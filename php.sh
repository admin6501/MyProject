#!/bin/bash

# تابع برای بررسی و نصب پیش‌نیازها
function check_and_install_prerequisites() {
    # بررسی و نصب PHP
    if ! command -v php &> /dev/null; then
        echo "PHP not found. Installing PHP..."
        sudo apt update
        sudo apt install -y php
    else
        echo "PHP is already installed."
    fi

    # بررسی و نصب Composer
    if ! command -v composer &> /dev/null; then
        echo "Composer not found. Installing Composer..."
        sudo apt install -y curl
        curl -sS https://getcomposer.org/installer | php
        sudo mv composer.phar /usr/local/bin/composer
    else
        echo "Composer is already installed."
    fi
}

# تابع برای نمایش منو
function show_menu() {
    echo "============================"
    echo " PHP Library Management "
    echo "============================"
    echo "1. Install a PHP library"
    echo "2. Uninstall a PHP library"
    echo "3. List installed PHP libraries"
    echo "4. Exit"
    echo "============================"
    read -p "Please select an option: " choice
}

# تابع برای نصب کتابخانه PHP
function install_library() {
    read -p "Enter the name of the library to install: " library
    if [ -n "$library" ]; then
        composer require $library
        echo "Library $library has been installed."
    else
        echo "Library name cannot be empty."
    fi
}

# تابع برای حذف کتابخانه PHP
function uninstall_library() {
    read -p "Enter the name of the library to uninstall: " library
    if [ -n "$library" ]; then
        composer remove $library
        echo "Library $library has been uninstalled."
    else
        echo "Library name cannot be empty."
    fi
}

# تابع برای لیست کردن کتابخانه‌های نصب شده PHP
function list_libraries() {
    composer show
}

# بررسی و نصب پیش‌نیازها
check_and_install_prerequisites

# حلقه اصلی منو
while true; do
    show_menu
    case $choice in
        1)
            install_library
            ;;
        2)
            uninstall_library
            ;;
        3)
            list_libraries
            ;;
        4)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done
