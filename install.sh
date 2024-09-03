#!/bin/bash

# Update the system
sudo apt update

# Install x-ui alireza panel
bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)

# Install certbot for Apache
sudo apt install certbot python3-certbot-apache -y

# Get domain information from the user
read -p "Please enter your domain name: " domain

# Automatically obtain SSL certificate
sudo certbot --apache -d $domain

# Edit the index.html file
sudo bash -c 'cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="fa">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Installation and Configuration Script</title>
</head>
<body>
    <h1>Installation and Configuration Successful</h1>
    <p>This server has been configured using an automated script that installs the x-ui alireza panel and sets up SSL using Certbot.</p>
    <button onclick="window.location.href=\'https://t.me/bash_khalil\'">Contact Support</button>
</body>
</html>
EOF'

echo "Installation and configuration completed successfully!"
