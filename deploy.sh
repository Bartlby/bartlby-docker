#!/bin/bash

PACKAGES_REQ="libssl-dev libssh-dev libmysqlclient-dev mysql-server autoconf gcc apache2 php5-cli  libapache2-mod-php5  libsnmp-dev libtool make php5-dev git openbsd-inetd supervisor openssh-server ncurses-dev libncursesw5-dev php-pear wget rrdtool g++ cron nagios-plugins nagios-plugins libfile-slurp-perl php5-sqlite php5-mysql php-net-smtp php-mail php-mail-mime"

show() {
  echo -e "\n\e[1;32m>>> $1\e[00m"
}
gpuf () {
   # git pull -f $1
   remote=${1:?"need remote to force pull from"}
 
   current_branch=$(git symbolic-ref -q HEAD)
   current_branch=${current_branch##refs/heads/}
   current_branch=${current_branch:-HEAD}
   if [ $current_branch = 'HEAD' ] ; then
       echo
       echo "On a detached head. Exiting..."
       exit 1
   fi 
 
   git fetch $remote $current_branch
   git reset --hard FETCH_HEAD
   git clean -df
}
app_start() {
	a2enmod rewrite #enable mod rewrite for pnp4nagios
	/etc/init.d/cron start
	/etc/init.d/mysql start
	/etc/init.d/apache2 start
	/etc/init.d/openbsd-inetd start
	/etc/init.d/ssh start
	chmod -v -R a+rwx /var/www/bartlby-ui
	chmod a+rwx /opt/bartlby/etc/bartlby.cfg
	rm /var/www/bartlby-ui/setup.php
	/opt/bartlby/bin/bartlby /opt/bartlby/etc/bartlby.cfg


	while ( true ) do
		sleep 10
	done

}
system_version() {

echo "FIXME";
#cd /usr/local/src/
#cd bartlby-core

#LOCAL_SHA=$(git rev-parse HEAD);
#CUR_SHA=$(wget -q -O /dev/stdout https://api.github.com/repos/Bartlby/bartlby-core/git/refs/heads/development/stage|grep sha|awk '{ gsub(/[,"]/, "", $2); print $2 }');

#if [ "$LOCAL_SHA" != "$CUR_SHA" ];



	
}
system_upgrade() {
	BACKUP_DIR="/tmp/$$.btl-upgrade/"
	mkdir $BACKUP_DIR

	show "System will be upgraded to latest development/stage"
	show "backup is located in: $BACKUP_DIR"
	
	cp -pva /opt/bartlby/etc/bartlby.cfg $BACKUP_DIR/ 
	cp -pva /var/www/bartlby-ui/ui-extra.conf $BACKUP_DIR/ 
	cp -pva /var/www/bartlby-ui/rights/ $BACKUP_DIR/rights/ 
	cp -pva /var/www/bartlby-ui/store/ $BACKUP_DIR/store/ 
	mysqldump -u root --password=docker bartlby > $BACKUP_DIR/mysql.dump 
	

	DEBIAN_FRONTEND=noninteractive apt-get install -y $PACKAGES_REQ

	killall -SIGUSR1 bartlby 
	
	


	#core
	show "updating core"
	cd /usr/local/src/bartlby-core/ 
	git stash 
	git checkout development/stage 
	git stash 
	gpuf origin 
	
# extensions
	show "updating bartlby-extensions"
	cd /usr/local/src/bartlby-extensions/ 
	git stash 
	git checkout development/stage 
	git stash 
	gpuf origin 
	
	./autogen.sh 
	./config.status 
	make clean
	make all
	make install 
	
	show "Building Core"
	cd /usr/local/src/bartlby-core/ 	
	
	./autogen.sh 
	#reconfigure
	./config.status 
	make clean all 
	show "stopping current core" 
	killall -SIGUSR1 bartlby 
	sleep 2 
	show "installing new binarys" 
	make install 
	show "you ll be guided threw the upgrade follow the instructions"
	show "MYSQL DATA (if you have not changed anything)"
	show "User: root, Password: docker, host: localhost, DB: bartlby"
	bash postinstall-pak 

	#php

	show "updating php module"
	cd /usr/local/src/bartlby-php/ 
	git stash 
	git checkout development/stage 
	git stash 
	gpuf origin 
	phpize 
	./configure 
	make install 


	show "updating UI:"
	cd /var/www/bartlby-ui/ 
	git stash 
	git checkout development/stage 
	gpuf origin 
	show "restoring store/ folder"
	cp -pva $BACKUP_DIR/store/* /var/www/bartlby-ui/store/ 
	chmod -R a+rwx /var/www/bartlby-ui 
	show "redoing pnp4nagios" 
	cd /var/www/bartlby-ui/ 
	ln -s /opt/pnp4nagios/var/perfdata pnp4data 

	show "updating agent"
	cd /usr/local/src/bartlby-agent 
	git stash 
	git checkout development/stage 
	gpuf origin 
	./autogen.sh 
	./config.status 
	make clean all install 

	/etc/init.d/openbsd-inetd restart 
	/etc/init.d/apache2 restart 

	show "UPGRADE DONE!"
	show "Backup is located in $BACKUP_DIR including mysql dump and config files"




}
system_setup()  {
	show "Setting root password to 'bartlby'"
	echo "root:bartlby" | chpasswd
	show "setting mysql password of root to 'docker'";
	echo "mysql-server mysql-server/root_password password docker" | debconf-set-selections
	echo "mysql-server mysql-server/root_password_again password docker" | debconf-set-selections
	DEBIAN_FRONTEND=noninteractive apt-get --yes update

	show "Installing packages"
	DEBIAN_FRONTEND=noninteractive apt-get install -y $PACKAGES_REQ
	sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

	show "install ncurses"
	pecl install  ncurses	

	show "installing bartlby-core"
	cd /usr/local/src/
	git clone https://github.com/Bartlby/bartlby-core
	cd /usr/local/src/bartlby-core
	git checkout development/stage
	./autogen.sh
	./configure --prefix=/opt/bartlby --enable-ssl --enable-ssh --enable-nrpe --enable-snmp
	make
	make install

	sed -i -e"s/^mysql_pw=/mysql_pw=docker/" /opt/bartlby/etc/bartlby.cfg
	sed -i -e"s/^user=bartlby/user=root/" /opt/bartlby/etc/bartlby.cfg
	/etc/init.d/mysql stop 
	/etc/init.d/mysql start
	echo "CREATE DATABASE bartlby " > CREA 
	mysql -u root --password=docker < CREA
	cd /opt/bartlby/ 
	mysql -u root --password=docker bartlby < mysql.shema;
	show "default DB imported username: admin password: password"

	show "registering inetd services, portier, agentv2"
	echo "bartlbyp                9031/tcp                        #Bartlby Portier" >> /etc/services
	echo "bartlbyp                stream  tcp     nowait.500      bartlby  /opt/bartlby/bin/bartlby_portier /opt/bartlby/etc/bartlby.cfg" >> /etc/inetd.conf
	echo "bartlbyv                9032/tcp                        #Bartlby Portier" >> /etc/services
	echo "bartlbyv                stream  tcp     nowait.500      bartlby  /opt/bartlby-agent/bartlby_agent_v2 /opt/bartlby-agent/bartlby.cfg" >> /etc/inetd.conf


	show "doing bartlby-php module"
	cd /usr/local/src/ && git clone https://github.com/Bartlby/bartlby-php
	cd /usr/local/src/bartlby-php
	git checkout development/stage
	phpize
	./configure
	make install

	show "enabling php extensions ncurses, bartlby"
	echo "extension=bartlby.so" > /etc/php5/apache2/conf.d/bartlby.ini
	echo "extension=ncurses.so" > /etc/php5/apache2/conf.d/ncurses.ini

	show "doing bartlby-ui"
	cd /var/www/
	git clone https://github.com/Bartlby/bartlby-ui/
	cd /var/www/bartlby-ui
	git checkout development/stage

	show "doing bartlby-agent"
	cd /usr/local/src/
	git clone https://github.com/Bartlby/bartlby-agent
	cd /usr/local/src/bartlby-agent
	git checkout development/stage
	./autogen.sh
	 ./configure --enable-ssl --prefix=/opt/bartlby-agent

	useradd bartlby
	make install
	sh postinstall-pak

	show "doing bartlby-plugins"
	cd /usr/local/src/
	git clone https://github.com/Bartlby/bartlby-plugins
	cd /usr/local/src/bartlby-plugins 
	./configure --prefix=/opt/bartlby-agent/plugins/
	make install


	#install bartlby-extensions

	cd /usr/local/src/
	git clone https://github.com/Bartlby/bartlby-extensions
	cd /usr/local/src/bartlby-extensions
	git checkout development/stage
	./autogen.sh
	./configure --prefix=/opt/bartlby-extensions
	make install

	#install pnp4nagios
	cd /usr/local/src
	wget http://docs.pnp4nagios.org/_media/dwnld/pnp4nagios-head.tar.gz
	tar xzvf pnp4nagios-head.tar.gz
	cd pnp4nagios-head
	./configure  --prefix=/opt/pnp4nagios --with-nagios-user=bartlby --with-nagios-group=root
	make all
	make install
	make install-html
	make install-processperfdata

	show "patching process perfdata"
	cd /opt/pnp4nagios/libexec/
	wget https://raw2.github.com/Bartlby/bartlby-docker/master/process_perfdata.pl.patch
	patch -p1 process_perfdata.pl < process_perfdata.pl.patch


	show "applying default CFG"
	mkdir /var/www/bartlby-ui/rrd/
	mkdir /opt/bartlby/var/log/history/

	chmod a+rwx /opt/bartlby/var/log/history/
	chmod a+rwx /var/www/bartlby-ui/rrd/

	cd /var/www/bartlby-ui/
	ln -s /opt/pnp4nagios/var/perfdata pnp4data

	wget -O /etc/apache2/sites-available/default https://raw2.github.com/Bartlby/bartlby-docker/master/apache-default
	wget -O /opt/bartlby/etc/bartlby.cfg https://raw2.github.com/Bartlby/bartlby-docker/master/bartlby.cfg
	wget -O /var/www/bartlby-ui/ui-extra.conf https://raw2.github.com/Bartlby/bartlby-docker/master/ui-extra.conf

	chmod a+rwx /opt/bartlby/etc/bartlby.cfg /var/www/bartlby-ui/ui-extra.conf

	show "registrering cron job for pnp4nagios"

	echo "" > CRONJOBS
	echo "*/10 * * * *  (/opt/pnp4nagios/libexec/process_perfdata.pl  -b /opt/pnp4nagios//var/perfdata.log)" >> CRONJOBS
	show "registering cron jobs for SiteManager";
	echo "*/2 * * * * (cd /var/www/bartlby-ui/extensions/; php automated.php username=admin password=password script=SiteManager/cron.php sync=SHM)" >> CRONJOBS
	echo "*/5 * * * * (cd /var/www/bartlby-ui/extensions/; php automated.php username=admin password=password script=SiteManager/cron.php sync=DB)" >> CRONJOBS
	echo "*/10 * * * * (cd /var/www/bartlby-ui/extensions/; php automated.php username=admin password=password script=SiteManager/cron.php sync=GENCONF)" >> CRONJOBS
	echo "*/10 * * * * (cd /var/www/bartlby-ui/extensions/; php automated.php username=admin password=password script=SiteManager/cron.php sync=FOLDERS)" >> CRONJOBS
	echo "0 0 * * * (cd /var/www/bartlby-ui/extensions/; php automated.php username=admin password=password script=SiteManager/cron.php sync=CLEANUP)" >> CRONJOBS
	
	show "registering cron jobs for autoReports";
	echo "0 2 * * * (cd /var/www/bartlby-ui/extensions/; php automated.php username=admin password=password script=AutoReports/cron.php wich=daily)" >> CRONJOBS
	echo "0 2 * * 7 (cd /var/www/bartlby-ui/extensions/; php automated.php username=admin password=password script=AutoReports/cron.php wich=weekly)" >> CRONJOBS

	show "registering cron jobs for OcL";
	echo "0 */1 * * * (cd /var/www/bartlby-ui/extensions/; php automated.php username=admin password=password script=OcL/cron.php)" >> CRONJOBS
	
	
	cat CRONJOBS|crontab -



	rm /opt/pnp4nagios/share/install.php

	show "installing nagios-plugins aka monitoring-plugins"

	cp /usr/lib/nagios/plugins/* /opt/bartlby-agent/plugins/


	wget -O /opt/bartlby/populate_sample_data.php  https://raw2.github.com/Bartlby/bartlby-docker/master/populate_sample_data.php
	cd /opt/bartlby/
	/opt/bartlby/bin/bartlby /opt/bartlby/etc/bartlby.cfg
	php populate_sample_data.php
	killall -SIGUSR1 bartlby


	chmod -v -R a+rwx /var/www/bartlby-ui
	show "Congratulations your bartlby instance is up and running you have a core with all extensions"

}
$1

