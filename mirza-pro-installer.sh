#!/bin/bash

clear

### --- Main Menu Function ---
main_menu() {
    echo "=============================="
    echo "   Mirza Pro Installer Menu   "
    echo "=============================="
    echo "1) Install Mirza Pro"
    echo "2) Exit"
    echo "------------------------------"
    read -p "Select an option: " CHOICE

    case $CHOICE in
        1) install_mirza ;;
        2) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid option!"; sleep 1; clear; main_menu ;;
    esac
}

### --- Install Function ---
install_mirza() {
    clear
    echo "=============================="
    echo "   Mirza Pro Installation     "
    echo "=============================="

    # Asking User Inputs
    read -p "Enter your domain (example: bot.example.com): " DOMAIN
    read -p "Enter your Telegram Bot Token: " BOT_TOKEN
    read -p "Enter your Telegram Admin ID: " ADMIN_ID
    read -p "Enter your Bot Username (without @): " BOT_USERNAME
    read -p "Enter Database Username: " DB_USER
    read -p "Enter Database Password: " DB_PASS

    echo "Config saved... starting installation."
    sleep 1

    echo ">>> Updating firewall..."
    sudo ufw allow 'Apache Full'
    sudo ufw reload

    echo ">>> Installing Apache..."
    sudo apt install apache2 -y

    echo ">>> Installing PHP 8.2..."
    sudo add-apt-repository ppa:ondrej/php -y
    sudo apt update
    sudo apt install -y php8.2 libapache2-mod-php8.2 php8.2-cli php8.2-common php8.2-mbstring php8.2-curl php8.2-xml php8.2-zip php8.2-mysql php8.2-gd php8.2-bcmath

    sudo a2dismod php7.4 php8.0 php8.1 2>/dev/null
    sudo a2enmod php8.2
    sudo systemctl restart apache2

    echo ">>> Installing MySQL..."
    sudo apt install mysql-server -y

    echo ">>> Creating database..."
    sudo mysql -e "
    CREATE DATABASE mirza_pro CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
    GRANT ALL PRIVILEGES ON mirza_pro.* TO '${DB_USER}'@'localhost';
    FLUSH PRIVILEGES;
    "

    echo ">>> Downloading Mirza Pro source..."
    cd /var/www
    sudo rm -rf mirza_pro
    sudo git clone https://github.com/mahdiMGF2/mirza_pro.git
    sudo chown -R www-data:www-data /var/www/mirza_pro

    echo ">>> Creating Apache VirtualHost..."
    sudo bash -c "cat > /etc/apache2/sites-available/mirza-pro.conf" << EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    DocumentRoot /var/www/mirza_pro

    <Directory /var/www/mirza_pro>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/mirza_error.log
    CustomLog \${APACHE_LOG_DIR}/mirza_access.log combined
</VirtualHost>
EOF

    sudo a2ensite mirza-pro.conf
    sudo a2dissite 000-default.conf
    sudo a2enmod rewrite
    sudo systemctl reload apache2

    echo ">>> Updating config.php..."
    CONFIG="/var/www/mirza_pro/config.php"

    sudo sed -i "s|\$usernamedb = .*|\$usernamedb = '${DB_USER}';|g" $CONFIG
    sudo sed -i "s|\$passworddb = .*|\$passworddb = '${DB_PASS}';|g" $CONFIG
    sudo sed -i "s|\$APIKEY      = .*|\$APIKEY      = '${BOT_TOKEN}';|g" $CONFIG
    sudo sed -i "s|\$adminnumber = .*|\$adminnumber = '${ADMIN_ID}';|g" $CONFIG
    sudo sed -i "s|\$domainhosts = .*|\$domainhosts = 'http://$DOMAIN';|g" $CONFIG
    sudo sed -i "s|\$usernamebot = .*|\$usernamebot = '${BOT_USERNAME}';|g" $CONFIG

    sudo systemctl restart apache2

    echo ">>> Creating database tables..."
    cd /var/www/mirza_pro
    php table.php

    echo ">>> Installing SSL..."
    sudo apt install certbot python3-certbot-apache -y
    sudo certbot --apache -d $DOMAIN

    sudo sed -i "s|http://$DOMAIN|https://$DOMAIN|g" $CONFIG
    sudo systemctl restart apache2

    echo ">>> Setting Telegram webhook..."
    curl "https://api.telegram.org/bot${BOT_TOKEN}/setWebhook?url=https://${DOMAIN}/index.php"

    echo ">>> Creating Cron Jobs..."
    (crontab -l 2>/dev/null; cat <<EOF
* * * * * php /var/www/mirza_pro/cronbot/NoticationsService.php >/dev/null 2>&1
*/5 * * * * php /var/www/mirza_pro/cronbot/uptime_panel.php >/dev/null 2>&1
*/5 * * * * php /var/www/mirza_pro/cronbot/uptime_node.php >/dev/null 2>&1
*/10 * * * * php /var/www/mirza_pro/cronbot/expireagent.php >/dev/null 2>&1
*/10 * * * * php /var/www/mirza_pro/cronbot/payment_expire.php >/dev/null 2>&1
0 * * * * php /var/www/mirza_pro/cronbot/statusday.php >/dev/null 2>&1
0 3 * * * * php /var/www/mirza_pro/cronbot/backupbot.php >/dev/null 2>&1
*/15 * * * * php /var/www/mirza_pro/cronbot/iranpay1.php >/dev/null 2>&1
*/15 * * * * php /var/www/mirza_pro/cronbot/plisio.php >/dev/null 2>&1
EOF
) | crontab -

    clear
    echo "============================================"
    echo "  Mirza Pro successfully installed!"
    echo "  Panel URL: https://$DOMAIN"
    echo "  Database User: $DB_USER"
    echo "============================================"
}

### --- Start Menu ---
main_menu
