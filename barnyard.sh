#!/usr/bin/env bash

error_msg(){
      echo "There is no environment variable to config mysql for barnyard writes" > /dev/stderr
      rm /etc/snort/config.lock
}

if [ -e /etc/snort/configured ]; then
	echo "Barnyard Configuration has been compeleted before this time..."
	barnyard2 -c /etc/snort/barnyard2.conf -d /var/log/snort -f snort.u2 -w /var/log/snort/barnyard2.waldo -g snort -u snort
	exit 0
fi

if [ ! -e /etc/snort/config.lock ]; then
   touch /etc/snort/config.lock
   if [ -z $mysql_host ]; then
	echo "MySQL Host Address is undefined" > /dev/stderr
	error_msg
   elif [ -z $mysql_user ]; then
	echo "MySQL Username is undefined" > /dev/stderr
	error_msg
   elif [ -z $mysql_password ]; then
	echo "MySQL password is undefined" > /dev/stderr
	error_msg
   elif [ -z $mysql_db ]; then
	echo "MySQL DatabaseName is undefined" > /dev/stderr
	error_msg
   elif [ -z $sensor_name ]; then
	echo "Sensor Name is undefined" > /dev/stderr
	error_msg
   else
        mysql --host=$mysql_host -u$mysql_user -p$mysql_password $mysql_db -e "source /opt/snort_src/barnyard2-master/schemas/create_mysql;"
        echo "output database: log, mysql, user=$mysql_user password=$mysql_password dbname=$mysql_db host=$mysql_host sensor name=$sensor_name" | tee -a /etc/snort/barnyard2.conf
	touch /etc/snort/configured 
        exit 0
   fi
fi

exit 1
