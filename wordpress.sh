#!/bin/bash

# Update the system
sudo apt update

# Install Apache
sudo apt install apache2 -y

# Install PHP 8 and required modules
sudo apt install php8.1 php8.1-mysql libapache2-mod-php8.1 php8.1-cli php8.1-cgi php8.1-gd -y

# Install MariaDB
sudo apt install mariadb-server mariadb-client -y

# Start and secure MariaDB
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo mysql_secure_installation

# Get database information from the user
read -p "Database name: " dbname
read -p "Database username: " dbuser
read -sp "Database password: " dbpass
echo

# Create database for WordPress
sudo mysql -u root -p -e "CREATE DATABASE $dbname;"
sudo mysql -u root -p -e "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';"
sudo mysql -u root -p -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';"
sudo mysql -u root -p -e "FLUSH PRIVILEGES;"

# Download and install Persian WordPress
cd /var/www/html
sudo wget https://fa.wordpress.org/latest-fa_IR.tar.gz
sudo tar -xvzf latest-fa_IR.tar.gz
sudo mv wordpress/* .
sudo rm -rf wordpress latest-fa_IR.tar.gz

# Set permissions
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# Disable Apache test page
sudo rm /var/www/html/index.html

# Create VirtualHost file for WordPress
sudo bash -c 'cat <<EOF > /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF'

# Enable VirtualHost
sudo a2ensite wordpress.conf
sudo a2enmod rewrite
sudo systemctl restart apache2

echo "WordPress installation completed successfully!"
