#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

LOGFILE="/tmp/mirza_pro_installer_$(date +%Y%m%d%H%M%S).log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "============================================"
echo "Mirza Pro Robust Installer - Start"
echo "Log: $LOGFILE"
echo "============================================"
sleep 1

fail() {
  echo ""
  echo "ERROR: $1"
  echo "Check the log: $LOGFILE"
  exit 1
}

# --- helper: retry command
retry() {
  local -r -i max_attempts="${1}"; shift
  local -r cmd=( "$@" )
  local -i attempt=1
  until "${cmd[@]}"; do
    if (( attempt == max_attempts )); then
      return 1
    fi
    echo "Command failed — retrying ($attempt/$max_attempts)..."
    attempt=$(( attempt + 1 ))
    sleep 2
  done
  return 0
}

# --- gather inputs (non-empty)
read -p "Enter your domain (example: bot.example.com): " DOMAIN
read -p "Enter your Telegram Bot Token: " BOT_TOKEN
read -p "Enter your Telegram Admin ID: " ADMIN_ID
read -p "Enter your Bot Username (without @): " BOT_USERNAME
read -p "Enter Database Username: " DB_USER
read -p "Enter Database Password: " DB_PASS

if [[ -z "$DOMAIN" || -z "$BOT_TOKEN" || -z "$ADMIN_ID" || -z "$BOT_USERNAME" || -z "$DB_USER" || -z "$DB_PASS" ]]; then
  fail "One or more required values are empty. Aborting."
fi

echo "Inputs collected. Starting setup..."

# --- ensure apt is not locked and update
echo "1/12 - Ensuring apt is usable..."
if pgrep -x apt >/dev/null || pgrep -x apt-get >/dev/null || lsof /var/lib/dpkg/lock >/dev/null 2>&1; then
  echo "Waiting for other apt/dpkg processes to finish..."
  sleep 3
fi

retry 3 sudo apt-get update --fix-missing || fail "apt update failed"
sudo apt-get upgrade -y || fail "apt upgrade failed"
sudo dpkg --configure -a || true
sudo apt-get --fix-broken install -y || true

# --- ensure required helper packages
echo "2/12 - Installing helper packages (software-properties-common, curl, wget, git)..."
retry 3 sudo apt-get install -y software-properties-common curl wget git ca-certificates lsb-release gnupg || fail "install helper packages failed"

# --- install/ensure UFW but safe: allow ssh first
echo "3/12 - UFW: installing and configuring safe defaults..."
if ! command -v ufw >/dev/null 2>&1; then
  sudo apt-get install -y ufw || fail "failed to install ufw"
fi

# ensure SSH allowed so enabling UFW won't lock you out
sudo ufw allow OpenSSH >/dev/null 2>&1 || true

# allow Apache profile if exists; if not, create minimal rules
if ufw status verbose | grep -q "Status: inactive"; then
  echo "UFW is inactive — enabling with safe rules..."
  # try to add apache profile; if not present, allow ports 80/443
  if sudo ufw app list 2>/dev/null | grep -q "Apache"; then
    sudo ufw allow 'Apache Full' || true
  else
    sudo ufw allow 80/tcp || true
    sudo ufw allow 443/tcp || true
  fi
  # enable non-interactively
  echo "y" | sudo ufw enable || echo "ufw enable returned non-zero (continuing)"
else
  echo "UFW already active."
  if sudo ufw app list 2>/dev/null | grep -q "Apache"; then
    sudo ufw allow 'Apache Full' || true
  else
    sudo ufw allow 80/tcp || true
    sudo ufw allow 443/tcp || true
  fi
fi

# --- install Apache
echo "4/12 - Installing Apache..."
retry 3 sudo apt-get install -y apache2 || fail "apache install failed"

# --- add PHP PPA and update
echo "5/12 - Adding PHP PPA (ondrej/php) and updating package lists..."
sudo add-apt-repository -y ppa:ondrej/php || true
retry 3 sudo apt-get update --fix-missing || fail "apt update after adding ppa failed"

# --- install PHP 8.2 and modules
echo "6/12 - Installing PHP 8.2 and common extensions..."
retry 3 sudo apt-get install -y php8.2 libapache2-mod-php8.2 php8.2-cli php8.2-common php8.2-mbstring php8.2-curl php8.2-xml php8.2-zip php8.2-mysql php8.2-gd php8.2-bcmath || {
  echo "Attempting to fix broken dependencies..."
  sudo apt-get --fix-broken install -y || true
  sudo dpkg --configure -a || true
  retry 2 sudo apt-get install -y php8.2 libapache2-mod-php8.2 php8.2-cli php8.2-common php8.2-mbstring php8.2-curl php8.2-xml php8.2-zip php8.2-mysql php8.2-gd php8.2-bcmath || fail "php install failed after fixes"
}

sudo a2dismod php7.4 php8.0 php8.1 2>/dev/null || true
sudo a2enmod php8.2 || true
sudo systemctl restart apache2 || true

# --- install MySQL server
echo "7/12 - Installing MySQL server..."
retry 3 sudo apt-get install -y mysql-server || {
  echo "Retrying mysql-server install with fixes..."
  sudo apt-get --fix-broken install -y || true
  sudo dpkg --configure -a || true
  retry 2 sudo apt-get install -y mysql-server || fail "mysql-server install failed"
}

# --- create database and user
echo "8/12 - Creating database and DB user (mirza_pro)..."
sudo mysql -e "CREATE DATABASE IF NOT EXISTS mirza_pro CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" || fail "create database failed"
sudo mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';" || fail "create db user failed"
sudo mysql -e "GRANT ALL PRIVILEGES ON mirza_pro.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;" || fail "grant privileges failed"

# --- download source (do not change names)
echo "9/12 - Downloading Mirza Pro source to /var/www/mirza_pro..."
cd /var/www || fail "/var/www not accessible"
sudo rm -rf mirza_pro
retry 3 sudo git clone https://github.com/mahdiMGF2/mirza_pro.git || fail "git clone failed"
sudo chown -R www-data:www-data /var/www/mirza_pro

# --- create virtualhost (keep filename mirza-pro.conf)
echo "10/12 - Creating Apache vhost (/etc/apache2/sites-available/mirza-pro.conf)..."
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

sudo a2ensite mirza-pro.conf || true
sudo a2dissite 000-default.conf || true
sudo a2enmod rewrite || true
sudo systemctl reload apache2 || true

# --- update config.php (only values, do not rename file)
CONFIG="/var/www/mirza_pro/config.php"
if [[ ! -f "$CONFIG" ]]; then
  fail "config.php not found at $CONFIG"
fi

echo "11/12 - Updating /var/www/mirza_pro/config.php values..."
# use perl regex for safer inline replace
sudo perl -0777 -pe "s/(\$usernamedb\s*=\s*').*?(';)/\${1}${DB_USER}\${2}/s" -i "$CONFIG"
sudo perl -0777 -pe "s/(\$passworddb\s*=\s*').*?(';)/\${1}${DB_PASS}\${2}/s" -i "$CONFIG"
sudo perl -0777 -pe "s/(\$APIKEY\s*=\s*').*?(';)/\${1}${BOT_TOKEN}\${2}/s" -i "$CONFIG"
sudo perl -0777 -pe "s/(\$adminnumber\s*=\s*').*?(';)/\${1}${ADMIN_ID}\${2}/s" -i "$CONFIG"
sudo perl -0777 -pe "s#(\$domainhosts\s*=\s*').*?(';)#\${1}http://${DOMAIN}\${2}#s" -i "$CONFIG"
sudo perl -0777 -pe "s/(\$usernamebot\s*=\s*').*?(';)/\${1}${BOT_USERNAME}\${2}/s" -i "$CONFIG"

sudo systemctl restart apache2 || true

# --- run table.php to create tables
echo "12/12 - Creating database tables (php table.php)..."
cd /var/www/mirza_pro || fail "cd to /var/www/mirza_pro failed"
php table.php || echo "Warning: php table.php returned non-zero (check $LOGFILE)"

# --- install certbot & obtain certificate (non-interactive)
echo "Obtaining Let's Encrypt certificate (certbot)..."
retry 3 sudo apt-get install -y certbot python3-certbot-apache || echo "certbot install warning"
# use register-unsafely-without-email to avoid interactive prompt if no email provided
sudo certbot --apache -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email || echo "certbot might have failed or cert already exists"

# update domainhttp->https in config.php if cert succeeded
sudo perl -0777 -pe "s#(\$domainhosts\s*=\s*').*?(';)#\${1}https://${DOMAIN}\${2}#s" -i "$CONFIG" || true
sudo systemctl restart apache2 || true

# --- set webhook
echo "Setting Telegram webhook..."
curl -s "https://api.telegram.org/bot${BOT_TOKEN}/setWebhook?url=https://${DOMAIN}/index.php" | tee /tmp/mirza_webhook_result.json || echo "curl to setWebhook failed (check /tmp/mirza_webhook_result.json)"

# --- adding crons safely (idempotent)
echo "Adding cron jobs..."
CRON_TMP="$(mktemp)"
crontab -l 2>/dev/null | sed '/mirza_pro\/cronbot/d' > "$CRON_TMP" || true
cat >> "$CRON_TMP" <<'CRON'
* * * * * php /var/www/mirza_pro/cronbot/NoticationsService.php >/dev/null 2>&1
*/5 * * * * php /var/www/mirza_pro/cronbot/uptime_panel.php >/dev/null 2>&1
*/5 * * * * php /var/www/mirza_pro/cronbot/uptime_node.php >/dev/null 2>&1
*/10 * * * * php /var/www/mirza_pro/cronbot/expireagent.php >/dev/null 2>&1
*/10 * * * * php /var/www/mirza_pro/cronbot/payment_expire.php >/dev/null 2>&1
0 * * * * php /var/www/mirza_pro/cronbot/statusday.php >/dev/null 2>&1
0 3 * * * php /var/www/mirza_pro/cronbot/backupbot.php >/dev/null 2>&1
*/15 * * * * php /var/www/mirza_pro/cronbot/iranpay1.php >/dev/null 2>&1
*/15 * * * * php /var/www/mirza_pro/cronbot/plisio.php >/dev/null 2>&1
CRON
crontab "$CRON_TMP" || echo "crontab install returned non-zero"
rm -f "$CRON_TMP"

echo ""
echo "============================================"
echo "Mirza Pro installation finished (check $LOGFILE)."
echo "If any step failed, review the log and re-run only the failing part."
echo "Panel URL (expected): https://${DOMAIN}"
echo "DB user: ${DB_USER}"
echo "============================================"
