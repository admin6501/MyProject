#!/bin/bash

# Function to add a user
add_user() {
    read -p "Enter the new username: " username
    sudo adduser $username
}

# Function to check if the user exists in system files
check_user_existence() {
    grep $username /etc/passwd
    grep $username /etc/shadow
    grep $username /etc/group
}

# Function to delete a user
delete_user() {
    read -p "Enter the username you want to delete: " username

    # Check if user exists before deletion
    echo "Checking for user existence before deletion:"
    check_user_existence

    sudo pkill -u $username  # Terminate all processes owned by the user
    sudo userdel -r $username
    sudo find / -user $username -exec rm -rf {} \;  # Remove all files owned by the user

    # Check if user exists after deletion
    echo "Checking for user existence after deletion:"
    check_user_existence
}

# Function to add a user to the sudo group
add_user_to_sudo() {
    read -p "Enter the username you want to add to the sudo group: " username
    sudo usermod -aG sudo $username
}

# Function to remove a user from the sudo group
remove_user_from_sudo() {
    read -p "Enter the username you want to remove from the sudo group: " username
    sudo deluser $username sudo
    sudo getent group sudo | grep $username && echo "$username is still in sudo group" || echo "$username removed from sudo group"
}

# Function to change a user's password
change_user_password() {
    read -p "Enter the username whose password you want to change: " username
    sudo passwd $username
}

# Main menu
while true; do
    echo "Please select an option:"
    echo "1. Add User"
    echo "2. Delete User"
    echo "3. Add User to Sudo Group"
    echo "4. Remove User from Sudo Group"
    echo "5. Change User Password"
    echo "6. Exit"
    read -p "Your choice: " choice

    case $choice in
        1)
            add_user
            ;;
        2)
            delete_user
            ;;
        3)
            add_user_to_sudo
            ;;
        4)
            remove_user_from_sudo
            ;;
        5)
            change_user_password
            ;;
        6)
            exit 0
            ;;
        *)
            echo "Invalid selection. Please try again."
            ;;
    esac
done
