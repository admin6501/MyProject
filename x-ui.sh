#!/bin/bash

# Function to add volume for all users
modify_volume_all_users() {
    read -p "Enter the volume (in GB) (use negative sign to subtract): " volume_gb
    # Convert GB to MB
    volume_mb=$(echo "$volume_gb * 1024" | bc)
    # Get the list of users
    users=$(x-ui list-users | awk '{print $1}')
    for username in $users; do
        # Command to add volume for the user without updating the panel
        result=$(x-ui update --user $username --volume $volume_mb --no-update)
        echo "Volume of $volume_gb GB ($volume_mb MB) has been added for user $username. Result: $result"
    done
}

# Function to add time for all users
modify_time_all_users() {
    read -p "Enter the time (in days) (use negative sign to subtract): " days
    # Get the list of users
    users=$(x-ui list-users | awk '{print $1}')
    for username in $users; do
        # Command to add time for the user without updating the panel
        result=$(x-ui update --user $username --days $days --no-update)
        echo "Time of $days days has been added for user $username. Result: $result"
    done
}

# Main menu
while true; do
    echo "Main Menu:"
    echo "1. Add Volume for All Users"
    echo "2. Add Time for All Users"
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
