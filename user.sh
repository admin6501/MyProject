#!/bin/bash

# Function to add a user
add_user() {
    read -p "Enter the new username: " username
    sudo adduser $username
}

# Function to delete a user
delete_user() {
    read -p "Enter the username you want to delete: " username
    sudo deluser --remove-home $username
}

# Function to add a user to the root group
add_user_to_root() {
    read -p "Enter the username you want to add to the root group: " username
    sudo usermod -aG root $username
}

# Function to remove a user from the root group
remove_user_from_root() {
    read -p "Enter the username you want to remove from the root group: " username
    sudo gpasswd -d $username root
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
    echo "3. Add User to Root Group"
    echo "4. Remove User from Root Group"
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
            add_user_to_root
            ;;
        4)
            remove_user_from_root
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
