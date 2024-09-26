#!/bin/bash

# Update custom build
cd /usr/local/directadmin/custombuild
./build update

# Set PHP versions
./build set php1_release 7.3
./build set php2_release 7.4
./build set php3_release 8.1
./build set php4_release 8.3

# Install PHP versions
./build php n

# Set ClamAV installation
./build set clamav yes

# Install ClamAV
./build clamav

echo "PHP versions and ClamAV have been successfully installed."
