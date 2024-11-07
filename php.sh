#!/bin/bash

# تابع برای بررسی و نصب پیش‌نیازها
function check_and_install_prerequisites() {
    # بررسی نصب بودن Composer
    if ! command -v composer &> /dev/null; then
        echo "Composer not found. Installing Composer..."
        EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
        php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
        ACTUAL_SIGNATURE="$(php -r "echo hash_file('SHA384', 'composer-setup.php');")"

        if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
            >&2 echo 'ERROR: Invalid installer signature'
            rm composer-setup.php
            exit 1
        fi

        php composer-setup.php --quiet
        RESULT=$?
        rm composer-setup.php
        if [ $RESULT -ne 0 ]; then
            echo "Composer installation failed."
            exit 1
        fi

        mv composer.phar /usr/local/bin/composer
        echo "Composer installed successfully."
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
