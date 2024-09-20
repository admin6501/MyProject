#!/bin/bash

# تابع برای نصب پیش‌نیازها
function install_dependencies() {
    if ! command -v zenity &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y zenity
    fi
    if ! command -v nc &> /dev/null; then
        sudo apt-get install -y netcat
    fi
    if ! command -v filebrowser &> /dev/null; then
        curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
    fi
}

# تابع برای نمایش پیام خطا
function show_error() {
    zenity --error --text="$1"
}

# تابع برای احراز هویت
function authenticate() {
    local input_username=$(zenity --entry --title="Login" --text="Enter Username:")
    local input_password=$(zenity --password --title="Login" --text="Enter Password:")

    if [[ "$input_username" == "$USERNAME" && "$input_password" == "$PASSWORD" ]]; then
        return 0
    else
        show_error "Invalid username or password"
        return 1
    fi
}

# تابع برای نمایش فایل‌ها
function show_files() {
    local files=$(ls -1)
    zenity --list --title="File Manager" --column="Files" $files
}

# تابع برای تغییر تنظیمات
function change_settings() {
    local choice=$(zenity --list --title="Settings" --column="Options" "Change Username" "Change Password" "Change Port" "Exit")

    case $choice in
        "Change Username")
            USERNAME=$(zenity --entry --title="Change Username" --text="Enter new username:")
            ;;
        "Change Password")
            PASSWORD=$(zenity --password --title="Change Password" --text="Enter new password:")
            ;;
        "Change Port")
            PORT=$(zenity --entry --title="Change Port" --text="Enter new port:")
            ;;
        "Exit")
            exit 0
            ;;
        *)
            show_error "Invalid option"
            ;;
    esac
}

# تابع برای آپلود فایل
function upload_file() {
    local file=$(zenity --file-selection --title="Select a file to upload")
    if [[ -n "$file" ]]; then
        cp "$file" .
        zenity --info --text="File uploaded successfully"
    fi
}

# تابع برای حذف فایل
function delete_file() {
    local file=$(zenity --file-selection --title="Select a file to delete")
    if [[ -n "$file" ]]; then
        rm -f "$file"
        zenity --info --text="File deleted successfully"
    fi
}

# تابع برای ایجاد پوشه
function create_folder() {
    local folder=$(zenity --entry --title="Create Folder" --text="Enter folder name:")
    if [[ -n "$folder" ]]; then
        mkdir -p "$folder"
        zenity --info --text="Folder created successfully"
    fi
}

# تابع برای حذف پوشه
function delete_folder() {
    local folder=$(zenity --file-selection --directory --title="Select a folder to delete")
    if [[ -n "$folder" ]]; then
        rm -rf "$folder"
        zenity --info --text="Folder deleted successfully"
    fi
}

# تابع برای باز کردن فایل
function open_file() {
    local file=$(zenity --file-selection --title="Select a file to open")
    if [[ -n "$file" ]]; then
        xdg-open "$file"
    fi
}

# تابع برای ویرایش فایل
function edit_file() {
    local file=$(zenity --file-selection --title="Select a file to edit")
    if [[ -n "$file" ]]; then
        xdg-open "$file"
    fi
}

# تابع برای انتقال فایل
function move_file() {
    local file=$(zenity --file-selection --title="Select a file to move")
    local destination=$(zenity --file-selection --directory --title="Select destination folder")
    if [[ -n "$file" && -n "$destination" ]]; then
        mv "$file" "$destination"
        zenity --info --text="File moved successfully"
    fi
}

# تابع برای دانلود فایل
function download_file() {
    local file=$(zenity --file-selection --title="Select a file to download")
    local destination=$(zenity --file-selection --directory --title="Select destination folder")
    if [[ -n "$file" && -n "$destination" ]]; then
        cp "$file" "$destination"
        zenity --info --text="File downloaded successfully"
    fi
}

# تابع برای ایجاد فایل
function create_file() {
    local file=$(zenity --entry --title="Create File" --text="Enter file name:")
    if [[ -n "$file" ]]; then
        touch "$file"
        zenity --info --text="File created successfully"
    fi
}

# تابع اصلی
function main() {
    install_dependencies

    # درخواست یوزرنیم، پسورد و پورت از کاربر
    USERNAME=$(zenity --entry --title="Setup" --text="Enter Username:")
    PASSWORD=$(zenity --password --title="Setup" --text="Enter Password:")
    PORT=$(zenity --entry --title="Setup" --text="Enter Port:")

    # اجرای Filebrowser
    filebrowser -p "$PORT" -a 0.0.0.0 -r . &

    # باز کردن مرورگر به صورت خودکار
    xdg-open "http://localhost:$PORT"

    if authenticate; then
        while true; do
            local choice=$(zenity --list --title="File Manager" --column="Options" \
                "Show Files" "Upload File" "Delete File" "Create Folder" "Delete Folder" \
                "Open File" "Edit File" "Move File" "Download File" "Create File" "Change Settings" "Exit")

            case $choice in
                "Show Files")
                    show_files
                    ;;
                "Upload File")
                    upload_file
                    ;;
                "Delete File")
                    delete_file
                    ;;
                "Create Folder")
                    create_folder
                    ;;
                "Delete Folder")
                    delete_folder
                    ;;
                "Open File")
                    open_file
                    ;;
                "Edit File")
                    edit_file
                    ;;
                "Move File")
                    move_file
                    ;;
                "Download File")
                    download_file
                    ;;
                "Create File")
                    create_file
                    ;;
                "Change Settings")
                    change_settings
                    ;;
                "Exit")
                    exit 0
                    ;;
                *)
                    show_error "Invalid option"
                    ;;
            esac
        done
    else
        change_settings
    fi
}

# شروع اسکریپت
main
