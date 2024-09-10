#!/bin/bash

# Display list of databases
databases=$(mysql -u root -p -e "SHOW DATABASES;" | tail -n +2)
echo "List of databases:"
i=1
for db in $databases; do
    echo "$i) $db"
    i=$((i+1))
done

# Get the database number from the user
read -p "Enter the number of the desired database: " db_number

# Get the name of the selected database
selected_db=$(echo "$databases" | sed -n "${db_number}p")

# Get the new username from the user
read -p "Enter the new username: " new_username

# Change the username in the selected database
mysql -u root -p -e "UPDATE mysql.user SET user='$new_username' WHERE user='root' AND host='localhost'; FLUSH PRIVILEGES;"

echo "The username for database $selected_db has been changed to $new_username."
