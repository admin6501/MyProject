#!/bin/bash

# Function to check and install necessary packages
install_packages() {
    if ! command -v docker &> /dev/null; then
        echo "Docker not found. Installing Docker..."
        sudo apt update
        sudo apt install -y docker.io
    else
        echo "Docker is already installed."
    fi

    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose not found. Installing Docker Compose..."
        sudo apt install -y docker-compose
    else
        echo "Docker Compose is already installed."
    fi
}

# Function to create the proxy
create_proxy() {
    read -p "Enter the port number for the proxy: " PORT
    read -p "Enter the secret key for the proxy: " SECRET

    # Create docker-compose.yml file
    cat <<EOF > docker-compose.yml
version: '3'
services:
  mtproxy:
    image: telegrammessenger/proxy:latest
    ports:
      - "\${PORT}:\${PORT}/tcp"
    environment:
      - SECRET=\${SECRET}
      - PORT=\${PORT}
EOF

    # Start the proxy
    sudo docker-compose up -d
    echo "Proxy created and running on port \${PORT}."
}

# Function to delete the proxy
delete_proxy() {
    sudo docker-compose down
    rm docker-compose.yml
    echo "Proxy deleted."
}

# Main menu
while true; do
    echo "1. Install necessary packages"
    echo "2. Create proxy"
    echo "3. Delete proxy"
    echo "4. Exit"
    read -p "Choose an option: " OPTION

    case \$OPTION in
        1) install_packages ;;
        2) create_proxy ;;
        3) delete_proxy ;;
        4) exit ;;
        *) echo "Invalid option. Please try again." ;;
    esac
done
