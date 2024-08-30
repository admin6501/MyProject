#!/bin/bash

# Function to add or subtract volume for all users
modify_volume_all_users() {
    read -p "Enter the volume (in MB) (use negative sign to subtract): " volume
    # Get the list of users
    users=$(x-ui list-users | awk '{print $1}')
    for username in $users; do
        # Command to add or subtract volume for the user
        x-ui update --user $username --volume $volume
        echo "Volume of $volume MB has been modified for user $username."
    done
}

# Function to add or subtract time for all users
modify_time_all_users() {
    read -p "Enter the time (in days) (use negative sign to subtract): " days
    # Get the list of users
    users=$(x-ui list-users | awk '{print $1}')
    for username in $users; do
        # Command to add or subtract time for the user
        x-ui update --user $username --days $days
        echo "Time of $days days has been modified for user $username."
    done
}

# Main menu
while true; do
    echo "Main Menu:"
    echo "1. Add/Subtract Volume for All Users"
    echo "2. Add/Subtract Time for All Users"
    echo "3. Exit"
    read -p "Please choose an option: " choice

    case $choice in
        1)
            modify_volume_all_users
            ;;
        2)
            modify_time_all_users
            ;;
        3)
            echo "Exiting the program."
            break
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done
