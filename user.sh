#!/bin/bash

show_menu() {
    echo "Please select an option:"
    echo "1) Create a new user"
    echo "2) Delete a user"
    echo "3) Grant sudo access to a user"
    echo "4) Remove sudo access from a user"
    echo "5) Exit"
}

create_user() {
    read -p "Enter the new username: " username
    read -sp "Enter the user's password: " password
    echo
    sudo adduser --gecos "" "$username" --disabled-password
    echo "$username:$password" | sudo chpasswd
    echo "User $username has been created successfully."
}

delete_user() {
    read -p "Enter the username you want to delete: " username
    sudo deluser "$username"
    echo "User $username has been deleted successfully."
}

grant_sudo() {
    read -p "Enter the username you want to grant sudo access to: " username
    sudo usermod -aG sudo "$username"
    echo "Sudo access has been granted to user $username."
}

remove_sudo() {
    read -p "Enter the username you want to remove sudo access from: " username
    sudo deluser "$username" sudo
    echo "Sudo access has been removed from user $username."
}

while true; do
    show_menu
    read -p "Your choice: " choice

    case $choice in
        1)
            create_user
            ;;
        2)
            delete_user
            ;;
        3)
            grant_sudo
            ;;
        4)
            remove_sudo
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done
