#!/bin/sh

NOTROOT='sudo -u vagrant'
PROJECTDIR=/project
TEMPLATES=/vagrant/vagrantdata

apt-get update

# base
apt-get install -q -y vim screen git curl tree

# mysql
PACKAGENAME=mysql-server
dpkg -s $PACKAGENAME >/dev/null 2>&1
if [ $? -eq 1 ]; then
	export DEBIAN_FRONTEND=noninteractive
	apt-get -q -y install $PACKAGENAME
	sed -i 's/^bind-address.*$/bind-address = 0.0.0.0/' /etc/mysql/my.cnf
	systemctl restart mysql.service
fi

# apache
PACKAGENAME=apache2
dpkg -s $PACKAGENAME >/dev/null 2>&1
if [ $? -eq 1 ]; then
	apt-get -q -y install $PACKAGENAME
	a2enmod rewrite
	systemctl restart apache2.service
fi

# php
PACKAGENAME=php5
dpkg -s $PACKAGENAME >/dev/null 2>&1
if [ $? -eq 1 ]; then
	apt-get -q -y install $PACKAGENAME php5-mysql phpunit php5-sqlite php5-xdebug
	cat $TEMPLATES/xdebug.ini.add >> /etc/php5/mods-available/xdebug.ini
	systemctl restart apache2.service
fi

###
# PROJECT sf3
PROJECTNAME='sf3'

[ ! -d $PROJECTDIR/$PROJECTNAME ] && mkdir $PROJECTDIR/$PROJECTNAME

cd $PROJECTDIR/$PROJECTNAME

if [ ! -f $PROJECTDIR/$PROJECTNAME/composer.phar ]; then

	$NOTROOT php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
	$NOTROOT php composer-setup.php
	$NOTROOT php -r "unlink('composer-setup.php');"
fi

if [ ! -f symfony ]; then
	curl -LsS https://symfony.com/installer -o symfony
	chmod a+x symfony
fi

###
# SITE symfony_demo
SITE=symfony_demo

[ ! -d $SITE ] && ./symfony demo

# session handler
grep -e 'handler_id:.*session.handler.native_file' \
	$SITE/app/config/config.yml >/dev/null \
	&& sed -i 's/handler_id:.*session.handler.native_file.*$/handler_id: ~/' \
		$SITE/app/config/config.yml

cd
	
if [ ! -f /etc/apache2/sites-available/$SITE.conf ]; then
	
	cat $TEMPLATES/apache.conf | \
		sed "s/PROJECTDIR/$PROJECTNAME\/$SITE\/web/g" \
			> /etc/apache2/sites-available/$SITE.conf
	
	sed -i "s/SITE/$SITE/g" /etc/apache2/sites-available/$SITE.conf
	
	a2ensite $SITE
	systemctl restart apache2.service
fi
