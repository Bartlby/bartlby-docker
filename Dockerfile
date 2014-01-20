FROM debian







RUN   echo "mysql-server mysql-server/root_password password docker" | debconf-set-selections
RUN   echo "mysql-server mysql-server/root_password_again password docker" | debconf-set-selections
RUN apt-get --yes update
RUN apt-get install -y libssl-dev libssh-dev libmysqlclient-dev mysql-server autoconf gcc apache2 php5-cli  libapache2-mod-php5  libsnmp-dev libtool make php5-dev git openbsd-inetd
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf



#checkout and compile core
RUN cd /usr/local/src/ && git clone https://github.com/Bartlby/bartlby-core
RUN cd /usr/local/src/bartlby-core && ./autogen.sh
RUN cd /usr/local/src/bartlby-core && ./configure --prefix=/opt/bartlby --enable-ssl --enable-ssh --enable-nrpe --enable-snmp
RUN cd /usr/local/src/bartlby-core && make
RUN cd /usr/local/src/bartlby-core && make install


RUN sed -i -e"s/^mysql_pw=/mysql_pw=docker/" /opt/bartlby/etc/bartlby.cfg
RUN /etc/init.d/mysql stop; /etc/init.d/mysql start; echo "CREATE DATABASE bartlby " > CREA && mysql -u root --password=docker < CREA; cd /opt/bartlby/ && mysql -u root --password=docker bartlby < mysql.shema; exit 0

# add PORTIER
RUN echo "bartlbyp                9031/tcp                        #Bartlby Portier" >> /etc/services
RUN echo "bartlbyp                stream  tcp     nowait.500      bartlby  ${BARTLBY_HOME}/bin/bartlby_portier ${BARTLBY_HOME}/etc/bartlby.cfg" >> /etc/inetd.conf

#checkout and compile PHP
RUN cd /usr/local/src/ && git clone https://github.com/Bartlby/bartlby-php
RUN cd /usr/local/src/bartlby-php && phpize
RUN cd /usr/local/src/bartlby-php && ./configure
RUN cd /usr/local/src/bartlby-php && make install
RUN echo "extension=bartlby.so" > /etc/php5/apache2/conf.d/bartlby.ini
#checkout UI
RUN cd /var/www/ && git clone https://github.com/Bartlby/bartlby-ui/

ADD docker_start.sh /opt/bartlby/docker_start.sh
RUN chmod +x /opt/bartlby/docker_start.sh

CMD ["/opt/bartlby/docker_start.sh"]

EXPOSE 80
VOLUME /opt/bartlby/var
VOLUME /var/www/
