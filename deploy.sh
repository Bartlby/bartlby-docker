#!/bin/bash


show() {
  echo -e "\n\e[1;32m>>> $1\e[00m"
}
system_setup()  {
show "Setting root password to 'bartlby'"
echo "root:bartlby" | chpasswd
show "setting mysql password of root to 'docker'";
echo "mysql-server mysql-server/root_password password docker" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password docker" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get --yes update

show "Installing packages"
DEBIAN_FRONTEND=noninteractive apt-get install -y libssl-dev libssh-dev libmysqlclient-dev mysql-server autoconf gcc apache2 php5-cli  libapache2-mod-php5  libsnmp-dev libtool make php5-dev git openbsd-inetd supervisor openssh-server ncurses-dev libncursesw5-dev php-pear wget rrdtool
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
./autogen.sh
 ./configure --enable-ssl --prefix=/opt/bartlby-agent

useradd bartlby
make install
sh postinstall-pak

show "doing monitoring-plugins"
cd /usr/local/src 
git clone https://github.com/monitoring-plugins/monitoring-plugins.git
cd monitoring-plugins/ 
./autgen.sh
./configure  --prefix=/opt/bartlby-agent/plugins/
make install
mv /opt/bartlby-agent/plugins/libexec/* /opt/bartlby-agent/plugins/

show "doing bartlby-plugins"
cd /usr/local/src/
git clone https://github.com/Bartlby/bartlby-plugins
cd /usr/local/src/bartlby-plugins 
./configure --prefix=/opt/bartlby-agent/plugins/
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

patch -p1 < process_perfdata.pl.patch

wget -O /etc/apache2/sites-available/default https://raw2.github.com/Bartlby/bartlby-docker/master/apache-default
wget -O /opt/bartlby/etc/bartlby.cfg https://raw2.github.com/Bartlby/bartlby-docker/master/bartlby.cfg
}
$1
