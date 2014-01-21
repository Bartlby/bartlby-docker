FROM debian
#docker run -p 49080:80 -p 49022:22 -p 49030:9030 -p 49040:9040  -name "bartlbycore" -d bartlby
#docker stop bartlbycore
#docker start bartlbycore



RUN echo "root:bartlby" | chpasswd



RUN   echo "mysql-server mysql-server/root_password password docker" | debconf-set-selections
RUN   echo "mysql-server mysql-server/root_password_again password docker" | debconf-set-selections
RUN  DEBIAN_FRONTEND=noninteractive apt-get --yes update
RUN  DEBIAN_FRONTEND=noninteractive apt-get install -y libssl-dev libssh-dev libmysqlclient-dev mysql-server autoconf gcc apache2 php5-cli  libapache2-mod-php5  libsnmp-dev libtool make php5-dev git openbsd-inetd supervisor openssh-server ncurses-dev libncursesw5-dev php-pear
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
RUN pecl install  ncurses



#checkout and compile core
RUN cd /usr/local/src/ && git clone https://github.com/Bartlby/bartlby-core

RUN cd /usr/local/src/bartlby-core && git checkout development/stage
RUN cd /usr/local/src/bartlby-core && ./autogen.sh

RUN cd /usr/local/src/bartlby-core && ./configure --prefix=/opt/bartlby --enable-ssl --enable-ssh --enable-nrpe --enable-snmp
RUN cd /usr/local/src/bartlby-core && make
RUN cd /usr/local/src/bartlby-core && make install


RUN sed -i -e"s/^mysql_pw=/mysql_pw=docker/" /opt/bartlby/etc/bartlby.cfg
RUN sed -i -e"s/^user=bartlby/user=root/" /opt/bartlby/etc/bartlby.cfg
RUN /etc/init.d/mysql stop; /etc/init.d/mysql start; echo "CREATE DATABASE bartlby " > CREA && mysql -u root --password=docker < CREA; cd /opt/bartlby/ && mysql -u root --password=docker bartlby < mysql.shema; exit 0

# add PORTIER
RUN echo "bartlbyp                9031/tcp                        #Bartlby Portier" >> /etc/services
RUN echo "bartlbyp                stream  tcp     nowait.500      bartlby  /opt/bartlby/bin/bartlby_portier /opt/bartlby/etc/bartlby.cfg" >> /etc/inetd.conf

#checkout and compile PHP
RUN cd /usr/local/src/ && git clone https://github.com/Bartlby/bartlby-php
RUN cd /usr/local/src/bartlby-php && git checkout development/stage
RUN cd /usr/local/src/bartlby-php && phpize
RUN cd /usr/local/src/bartlby-php && ./configure
RUN cd /usr/local/src/bartlby-php && make install
RUN echo "extension=bartlby.so" > /etc/php5/apache2/conf.d/bartlby.ini
RUN echo "extension=ncurses.so" > /etc/php5/apache2/conf.d/ncurses.ini
#checkout UI
RUN cd /var/www/ && git clone https://github.com/Bartlby/bartlby-ui/
RUN cd /var/www/bartlby-ui && git checkout development/stage


RUN cd /usr/local/src/ && git clone https://github.com/Bartlby/bartlby-agent
RUN cd /usr/local/src/bartlby-agent && ./autogen.sh
RUN cd /usr/local/src/bartlby-agent && ./configure --enable-ssl --prefix=/opt/bartlby-agent

RUN cd /usr/local/src/bartlby-agent && useradd bartlby
RUN cd /usr/local/src/bartlby-agent && make install; exit 0
RUN cd /usr/local/src/bartlby-agent && sh postinstall-pak; exit 0


#add plugins (monitoring-plugins, bartlby-plugins)
RUN cd /usr/local/src && git clone https://github.com/monitoring-plugins/monitoring-plugins.git
RUN cd /usr/local/src/monitoring-plugins/ && ./autgen.sh
RUN cd /usr/local/src/monitoring-plugins/ && ./configure  --prefix=/opt/bartlby-agent/plugins/
RUN cd /usr/local/src/monitoring-plugins/ && make install
RUN cd /usr/local/src/monitoring-plugins/ && mv /opt/bartlby-agent/plugins/libexec/* /opt/bartlby-agent/plugins/
RUN cd /usr/local/src && git clone https://github.com/Bartlby/bartlby-plugins
RUN cd /usr/local/src/bartlby-plugins && ./configure --prefix=/opt/bartlby-agent/plugins/
RUN cd /usr/local/src/bartlby-plugins && make install


ADD docker_start.sh /opt/bartlby/docker_start.sh

RUN chmod +x /opt/bartlby/docker_start.sh

CMD ["/opt/bartlby/docker_start.sh"]

EXPOSE 80 22 9030
VOLUME /opt/bartlby/var
VOLUME /var/www/
