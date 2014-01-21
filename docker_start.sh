#!/bin/bash
a2enmod rewrite #enable mod rewrite for pnp4nagios
/etc/init.d/mysql start
/etc/init.d/apache2 start
/etc/init.d/openbsd-inetd start
/etc/init.d/ssh start
chmod -v -R a+rwx /var/www/bartlby-ui
chmod a+rwx /opt/bartlby/etc/bartlby.cfg
rm /var/www/bartlby-ui/setup.php
/opt/bartlby/bin/bartlby /opt/bartlby/etc/bartlby.cfg


#wait for bartlby
while ( true ) do
sleep 1
done
