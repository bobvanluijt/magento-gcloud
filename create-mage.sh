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

apt-get -qy install nginx git-core mysql-client-5.7 php7.0-fpm php7.0-mcrypt php7.0-curl php7.0-cli php7.0-mysql php7.0-gd php7.0-xsl php7.0-json php7.0-intl php-pear php7.0-dev php7.0-common php7.0-mbstring php7.0-zip php-soap libcurl3 curl

# set limits
echo "memory_limit = 512M
max_execution_time = 1800
zlib.output_compression = On" >> /etc/php/7.0/fpm/php.ini

echo "memory_limit = 512M
max_execution_time = 1800
zlib.output_compression = On" >> /etc/php/7.0/cli/php.ini

echo "What is the host ip of the database: "
read DBHOST

mysql_config_editor set --login-path=local --host=${DBHOST} --user=root --password

echo "What name do you want to use for the DB? "
read DBNAME

mysql --login-path=local -e "create database IF NOT EXISTS ${DBNAME}; create user IF NOT EXISTS magentouser@localhost; grant all privileges on ${DBNAME}.* to 'magentouser'@'%' IDENTIFIED BY 'magentopass'; flush privileges;"

# Install composer
cd ~/
curl -sS https://getcomposer.org/installer | php

mv composer.phar /usr/bin/composer

cd /var/www/
wget https://github.com/magento/magento2/archive/2.1.1.tar.gz
tar -xzf 2.1.1.tar.gz
mv magento2-2.1.1/ magento2/

# Install sample data
cd /var/www
git clone https://github.com/magento/magento2-sample-data.git
cd magento2-sample-data/dev/tools
php -f build-sample-data.php -- --ce-source="/var/www/magento2"

cd /var/www/magento2
find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \;
find ./var -type d -exec chmod 777 {} \;
find ./pub/media -type d -exec chmod 777 {} \;
find ./pub/static -type d -exec chmod 777 {} \;
chmod 777 ./app/etc
chmod 644 ./app/etc/*.xml
composer install

chmod +x /var/www/magento2/bin/magento

/var/www/magento2/bin/magento setup:install --backend-frontname="adminlogin" \
--key="biY8vdWx4w8KV5Q59380Fejy36l6ssUb" \
--db-host="${DBHOST}" \
--db-name="${DBNAME}" \
--db-user="magentouser" \
--db-password="magentopass" \
--language="en_US" \
--currency="USD" \
--timezone="America/New_York" \
--use-rewrites=1 \
--use-secure=0 \
--base-url="http://www.newmagento.com" \
--base-url-secure="https://www.newmagento.com" \
--admin-user=adminuser \
--admin-password=admin123@ \
--admin-email=admin@newmagento.com \
--admin-firstname=admin \
--admin-lastname=user \
--cleanup-database

cd /var/www/magento2/
chmod 700 /var/www/magento2/app/etc
chown -R www-data:www-data .

rm /etc/nginx/sites-enabled/default
wget -O /etc/nginx/sites-enabled/default https://raw.githubusercontent.com/bobvanluijt/magento-gcloud/master/magento

service php7.0-fpm restart
service nginx restart
