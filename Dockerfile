FROM debian




RUN apt-get --yes update
RUN apt-get install -y libssl-dev libssh-dev libmysqlclient-dev mysql-server autoconf gcc apache2 php5-cli  libapache2-mod-php5


RUN   echo "mysql-server mysql-server/root_password password docker" | debconf-set-selections
RUN   echo "mysql-server mysql-server/root_password_again password docker" | debconf-set-selections

RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

EXPOSE 80
