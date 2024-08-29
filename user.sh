#!/bin/bash

# Function to display the menu
show_menu() {
    echo "1. Add User"
    echo "2. Change User Password"
    echo "3. Add User to Root Group"
    echo "4. Remove User from Root Group"
    echo "5. Delete User Completely"
    echo "6. Exit"
}

# Function to add a user
add_user() {
    read -p "Enter new username: " username
    sudo adduser $username
}

# Function to change user password
change_password() {
    read -p "Enter username: " username
    sudo passwd $username
}

# Function to add user to root group
add_to_root() {
    read -p "Enter username: " username
    sudo usermod -aG root $username
}

# Function to remove user from root group
remove_from_root() {
    read -p "Enter username: " username
    sudo gpasswd -d $username root
}

# Function to delete user completely
delete_user() {
    read -p "Enter username: " username
    sudo userdel -r $username
}

# Main loop to display the menu and get user input
while true; do
    show_menu
    read -p "Choose an option: " choice
    case $choice in
        1) add_user ;;
        2) change_password ;;
        3) add_to_root ;;
        4) remove_from_root ;;
        5) delete_user ;;
        6) exit 0 ;;
        *) echo "Invalid choice!" ;;
    esac
done
