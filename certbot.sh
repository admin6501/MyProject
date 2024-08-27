#!/bin/bash

# Install Certbot
echo "Updating repositories and installing Certbot..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y certbot python3-certbot-apache

# Check if Certbot was installed successfully
if ! command -v certbot &> /dev/null; then
    echo "Certbot could not be installed. Please check your network connection and package sources."
    exit 1
fi

# Ask the user for the subdomain
read -p "Please enter your subdomain: " subdomain

# Run Certbot to obtain SSL
echo "Obtaining SSL for $subdomain ..."
sudo certbot --apache -d $subdomain

# Check Certbot status
if [ $? -ne 0 ]; then
    echo "Error obtaining SSL. Please try again."
    exit 1
fi

# Display the paths of the SSL files
echo "SSL successfully installed."
echo "Path to fullchain.pem: /etc/letsencrypt/live/$subdomain/fullchain.pem"
echo "Path to privkey.pem: /etc/letsencrypt/live/$subdomain/privkey.pem"
