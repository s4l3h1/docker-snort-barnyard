#!/bin/bash

set -x

if [ ! -e /etc/snort/config.lock ]; then
   mysql --host=$mysql_host -u$mysql_user -p$mysql_password $mysql_db -e "source /opt/snort_src/barnyard2-master/schemas/create_mysql;"
   echo "output database: log, mysql, user=$mysql_user password=$mysql_password dbname=$mysql_db host=$mysql_host sensor name=$sensor_name" | tee -a /etc/snort/barnyard2.conf
   touch /etc/snort/config.lock
fi
exit 0
