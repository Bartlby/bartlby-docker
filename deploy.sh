#!/bin/bash

PACKAGES_REQ="python-pip python-dev git"


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

	mkdir /opt/bartlby/patches/

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
	
	apt-get clean && apt-get update
	DEBIAN_FRONTEND=noninteractive apt-get install -y $PACKAGES_REQ
	pip install ansible
	show "updating ansible roles/playbooks"
	cd /usr/local/src/bartlby-ansible/ 
	git stash 
	git checkout  master
	git stash 
	gpuf origin 
	

	echo "[local]" > local
	echo "localhost" >> local
	ansible-galaxy install geerlingguy.apache
	ansible-galaxy install geerlingguy.php-pecl
 	ansible-galaxy install geerlingguy.mysql
	
	ansible-playbook -i local -c local playbooks/bartlby-devbox.yml


	
	
	
	

}
system_setup()  {
	show "Setting root password to 'bartlby'"
	echo "root:bartlby" | chpasswd
	
	system_upgrade
	
	
	show "Congratulations your bartlby instance is up and running you have a core with all extensions"

}
$1
