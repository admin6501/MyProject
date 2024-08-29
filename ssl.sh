#!/bin/bash

# Path to the log file
LOGFILE="/var/log/ssl_renew.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOGFILE
}

# Function to list certificates
list_certificates() {
    certbot certificates | grep "Certificate Name:" | awk '{print NR ". " $3}'
}

# Function to renew a specific certificate
renew_certificate() {
    local domain=$1
    log_message "Starting renewal for $domain"
    certbot renew --cert-name $domain --apache
    if [ $? -eq 0 ]; then
        log_message "Renewal successful for $domain"
    else
        log_message "Error in renewal for $domain"
    fi
}

# Main script
log_message "Listing all certificates"
certificates=$(list_certificates)
echo "Available certificates:"
echo "$certificates"

read -p "Enter the number of the certificate you want to renew: " cert_number
domain=$(echo "$certificates" | awk -v num=$cert_number 'NR==num {print $2}')

if [ -n "$domain" ]; then
    renew_certificate $domain
else
    log_message "Invalid certificate number"
    echo "Invalid certificate number"
fi
