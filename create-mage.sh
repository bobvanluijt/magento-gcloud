################################
# Magento setup by @bobvanluijt
################################

#!/bin/bash

# Run the script as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

apt-get update

apt-get install nginx -qq -y

apt-get install mysql-client-5.7 php7.0-fpm php7.0-mcrypt php7.0-curl php7.0-cli php7.0-mysql php7.0-gd php7.0-xsl php7.0-json php7.0-intl php-pear php7.0-dev php7.0-common php7.0-mbstring php7.0-zip php-soap libcurl3 curl -y

echo "memory_limit = 512M
max_execution_time = 1800
zlib.output_compression = On" >> /etc/php/7.0/fpm/php.ini

echo "memory_limit = 512M
max_execution_time = 1800
zlib.output_compression = On" >> /etc/php/7.0/cli/php.ini

echo "What is the host ip of the database: "
read DBHOST

mysql_config_editor set --login-path=local --host=${DBHOST} --user=root --password

mysql --login-path=local -e "create database magentodb; create user magentouser@localhost identified by 'magentouser@'; grant all privileges on magentodb.* to 'magentouser'@'%' IDENTIFIED BY 'magentopass'; flush privileges;"

# Install composer
cd ~/
curl -sS https://getcomposer.org/installer | php

mv composer.phar /usr/bin/composer

cd /var/www/
wget https://github.com/magento/magento2/archive/2.1.1.tar.gz
tar -xzvf 2.1.1.tar.gz
mv magento2-2.1.1/ magento2/

cd /var/www/magento2
find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \;
find ./var -type d -exec chmod 777 {} \;
find ./pub/media -type d -exec chmod 777 {} \;
find ./pub/static -type d -exec chmod 777 {} \;
chmod 777 ./app/etc
chmod 644 ./app/etc/*.xml
composer install

rm /etc/nginx/sites-enabled/default
wget -O /etc/nginx/sites-enabled/default https://raw.githubusercontent.com/bobvanluijt/magento-gcloud/master/magento

service php7.0-fpm restart
service nginx restart
