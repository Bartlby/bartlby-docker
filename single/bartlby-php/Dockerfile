 FROM debian
 ENV CAH 2
 MAINTAINER hjanuschka
 RUN apt-get -y update
 RUN apt-get install -y ansible git
 RUN git clone http://github.com/Bartlby/bartlby-ansible.git /usr/local/src/bartlby-ansible/
 ADD inventory /etc/ansible/hosts
 ADD loop /bin/docker-loop
 RUN chmod +x /bin/docker-loop
 WORKDIR /usr/local/src/bartlby-ansible
 RUN ansible-playbook -c local playbooks/bartlby-php.yml
 EXPOSE 9030 22
 CMD "/bin/docker-loop"
