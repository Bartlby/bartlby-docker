#!/bin/bash
/etc/init.d/mysql start
/etc/init.d/apache2 start
/etc/init.d/openbsd-inted start
/opt/bartlby/bin/bartlby -d -r /opt/bartlby/etc/bartlby.cfg
