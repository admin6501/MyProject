#!/bin/bash

# Install Python and pip
install_python_pip() {
    echo "Installing Python and pip..."
    sudo apt update
    sudo apt install -y python3 python3-pip
    echo "Python and pip installed successfully."
}

# List installed libraries
list_libraries() {
    echo "Installed libraries:"
    pip list --format=columns | awk 'NR>2 {print NR-2 ". " $1}'
}

# Install library
install_library() {
    read -p "Enter the name of the library you want to install: " lib_name
    pip install $lib_name
    echo "Library $lib_name installed successfully."
}

# Uninstall library
uninstall_library() {
    read -p "Enter the name of the library you want to uninstall: " lib_name
    pip uninstall -y $lib_name
    echo "Library $lib_name uninstalled successfully."
}

# Main menu
main_menu() {
    while true; do
        echo "Please select an option:"
        echo "1. Install Python and pip"
        echo "2. List installed libraries"
        echo "3. Install library"
        echo "4. Uninstall library"
        echo "5. Exit"
        read -p "Your choice: " choice

        case $choice in
            1) install_python_pip ;;
            2) list_libraries ;;
            3) install_library ;;
            4) uninstall_library ;;
            5) exit 0 ;;
            *) echo "Invalid choice. Please try again." ;;
        esac
    done
}

# Run the main menu
main_menu
