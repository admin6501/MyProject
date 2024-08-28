#!/bin/bash

# نصب Python و pip
install_python_pip() {
    echo "در حال نصب Python و pip..."
    sudo apt update
    sudo apt install -y python3 python3-pip
    echo "Python و pip با موفقیت نصب شدند."
}

# نمایش کتابخانه‌های نصب شده
list_libraries() {
    echo "کتابخانه‌های نصب شده:"
    pip list --format=columns | awk 'NR>2 {print NR-2 ". " $1}'
}

# نصب کتابخانه
install_library() {
    read -p "نام کتابخانه‌ای که می‌خواهید نصب کنید را وارد کنید: " lib_name
    pip install $lib_name
    echo "کتابخانه $lib_name با موفقیت نصب شد."
}

# حذف کتابخانه
uninstall_library() {
    read -p "نام کتابخانه‌ای که می‌خواهید حذف کنید را وارد کنید: " lib_name
    pip uninstall -y $lib_name
    echo "کتابخانه $lib_name با موفقیت حذف شد."
}

# منوی اصلی
main_menu() {
    while true; do
        echo "لطفاً یک گزینه را انتخاب کنید:"
        echo "1. نصب Python و pip"
        echo "2. نمایش کتابخانه‌های نصب شده"
        echo "3. نصب کتابخانه"
        echo "4. حذف کتابخانه"
        echo "5. خروج"
        read -p "انتخاب شما: " choice

        case $choice in
            1) install_python_pip ;;
            2) list_libraries ;;
            3) install_library ;;
            4) uninstall_library ;;
            5) exit 0 ;;
            *) echo "انتخاب نامعتبر است. لطفاً دوباره تلاش کنید." ;;
        esac
    done
}

# اجرای منوی اصلی
main_menu
