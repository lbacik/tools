#!/bin/sh

NOTROOT='sudo -u vagrant'
PROJECTDIR=/project
TEMPLATES=/vagrant/vagrantdata

apt-get update

# base
apt-get install -q -y vim screen git curl tree

# mysql
export DEBIAN_FRONTEND=noninteractive
apt-get -q -y install mysql-server
sed -i 's/^bind-address.*$/bind-address = 0.0.0.0/' /etc/mysql/my.cnf
systemctl restart mysql.service

# apache
apt-get -q -y install apache2
a2enmod rewrite
systemctl restart apache2.service

# php
apt-get -q -y install php5 php5-mysql phpunit php5-sqlite php5-xdebug
cat $TEMPLATES/xdebug.ini.add >> /etc/php5/mods-available/xdebug.ini
systemctl restart apache2.service

###
# PROJECT sf3
PROJECTNAME='sf3'

mkdir $PROJECTDIR/$PROJECTNAME

cd $PROJECTDIR/$PROJECTNAME

# composer
$NOTROOT php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
$NOTROOT php composer-setup.php
$NOTROOT php -r "unlink('composer-setup.php');"

#symfony
curl -LsS https://symfony.com/installer -o symfony
chmod a+x symfony

###
# SITE symfony_demo
SITE=symfony_demo

./symfony demo

# session handler
sed -i 's/handler_id:.*session.handler.native_file.*$/handler_id: ~/' \
		$SITE/app/config/config.yml

cd
	
cat $TEMPLATES/apache.conf | \
	sed "s/PROJECTDIR/$PROJECTNAME\/$SITE\/web/g" \
		> /etc/apache2/sites-available/$SITE.conf
	
sed -i "s/SITE/$SITE/g" /etc/apache2/sites-available/$SITE.conf
	
a2ensite $SITE
systemctl restart apache2.service
