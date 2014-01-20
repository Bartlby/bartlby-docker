FROM debian




RUN apt-get --yes update
RUN apt-get install -y libssl-dev libssh-dev libmysqlclient-dev mysql-server autoconf gcc apache2 php5-cli  libapache2-mod-php5 php5-ncurses libsnmp-dev libtool make php5-dev


RUN   echo "mysql-server mysql-server/root_password password docker" | debconf-set-selections
RUN   echo "mysql-server mysql-server/root_password_again password docker" | debconf-set-selections
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

#checkout and compile core
  # add PORTIER
#checkout and compile PHP
#checkout and compile PLUGINS
#checkout and compile AGENT
#checkout UI

#publish a default DB
#make the UI in the document root

#start apache
#start mysql
#run bartlby.deamon in FG

#export volumes
  # /opt/bartlby/var/

#open PORT FOR UI
EXPOSE 80
#open PORT FOR AGENT
#open PORT FOR PORTIER
