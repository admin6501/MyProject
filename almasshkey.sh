
#!/bin/bash

# Function to check if the script is run as root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "این اسکریپت باید با دسترسی روت اجرا شود."
        exit 1
    fi
}

# Function to remove SSH keys
remove_ssh_keys() {
    echo "در حال حذف کلیدهای SSH..."
    rm -f /root/.ssh/authorized_keys
    rm -f /root/.ssh/id_rsa /root/.ssh/id_rsa.pub
    echo "کلیدهای SSH حذف شدند."
}

# Function to enable password authentication
enable_password_auth() {
    echo "در حال فعال کردن احراز هویت با رمز عبور..."
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    systemctl restart sshd
    echo "احراز هویت با رمز عبور فعال شد."
}

# Function to set new root password
set_root_password() {
    echo "لطفاً یک رمز عبور جدید برای کاربر روت وارد کنید:"
    passwd root
}

# Main script
check_root
remove_ssh_keys
enable_password_auth
set_root_password

echo "تنظیمات SSH با موفقیت انجام شد. اکنون فقط ورود با رمز عبور برای کاربر روت فعال است."
