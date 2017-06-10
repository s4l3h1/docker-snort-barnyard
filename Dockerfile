FROM ubuntu:xenial
MAINTAINER Muhammad Salehi <salehi1994@gmail.com>
ENV DEBIAN_FRONTEND noninteractive
ENV COVERALLS_TOKEN [secure]
ENV CC gcc
ENV CXX g++
ADD sources.list /etc/apt/sources.list
RUN apt-get update && apt upgrade -y ;\
apt-get install cron net-tools ethtool inetutils-ping git wget build-essential libpcap-dev libpcre3-dev libdumbnet-dev bison flex zlib1g-dev liblzma-dev openssl libssl-dev libnghttp2-dev  python-pip supervisor libmysqlclient-dev mysql-client autoconf libtool libcrypt-ssleay-perl liblwp-useragent-determined-perl -y ;\
apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ;\
mkdir /opt/snort_src
WORKDIR /opt/snort_src
RUN wget -c -t 0 https://snort.org/downloads/snort/daq-2.0.6.tar.gz ;\
tar -xvzf daq-2.0.6.tar.gz; cd daq-2.0.6; ./configure; make; make install; cd ..;\
wget https://snort.org/downloads/snort/snort-2.9.9.0.tar.gz ;\
tar -xvzf snort-2.9.9.0.tar.gz; cd snort-2.9.9.0; ./configure --enable-sourcefire; make; make install; cd ..;\
ldconfig ;\
snort -V ;\
groupadd snort ;\
useradd snort -r -s /sbin/nologin -c SNORT_IDS -g snort ;\
mkdir /etc/snort ;\
mkdir /etc/snort/rules ;\
mkdir /etc/snort/rules/iplists ;\
mkdir /etc/snort/preproc_rules ;\
mkdir /usr/local/lib/snort_dynamicrules ;\
mkdir /etc/snort/so_rules ;\
touch /etc/snort/rules/iplists/black_list.rules ;\
touch /etc/snort/rules/iplists/white_list.rules ;\
touch /etc/snort/rules/local.rules ;\
touch /etc/snort/sid-msg.map ;\
touch /etc/snort/rules/white_list.rules ;\
touch /etc/snort/rules/black_list.rules ;\
mkdir /var/log/snort ;\
mkdir /var/log/snort/archived_logs ;\
chmod -R 5775 /etc/snort ;\
chmod -R 5775 /var/log/snort ;\
chmod -R 5775 /var/log/snort/archived_logs ;\
chmod -R 5775 /etc/snort/so_rules ;\
chmod -R 5775 /usr/local/lib/snort_dynamicrules ;\
chown -R snort:snort /etc/snort ;\
chown -R snort:snort /var/log/snort ;\
chown -R snort:snort /usr/local/lib/snort_dynamicrules 
cp -fv /opt/snort_src/snort-2.9.9.0/etc/{*.map,*.dtd,*.conf*} /etc/snort ;\
cp -rfv /opt/snort_src/snort-2.9.9.0/src/dynamic-preprocessors/build/usr/local/lib/snort_dynamicpreprocessor /usr/local/lib/
ADD snort.conf /etc/snort/snort.conf
WORKDIR /opt/snort_src
RUN wget https://github.com/firnsy/barnyard2/archive/master.tar.gz -O barnyard2-Master.tar.gz
RUN tar zxvf barnyard2-Master.tar.gz
RUN cd barnyard2-master ; autoreconf -fvi -I ./m4
RUN ln -s /usr/include/dumbnet.h /usr/include/dnet.h
RUN ldconfig
RUN cd barnyard2-master; ./configure --with-mysql --with-mysql-libraries=/usr/lib/x86_64-linux-gnu; make -j32; make install
RUN /usr/local/bin/barnyard2 -V
RUN cp -fv /opt/snort_src/barnyard2-master/etc/barnyard2.conf /etc/snort/
# the /var/log/barnyard2 folder is never used or referenced
# but barnyard2 will error without it existing
RUN mkdir /var/log/barnyard2
RUN chown snort.snort /var/log/barnyard2
RUN touch /var/log/snort/barnyard2.waldo
RUN chown snort.snort /var/log/snort/barnyard2.waldo
RUN chmod o-r /etc/snort/barnyard2.conf
ADD superv.conf /etc/supervisor/conf.d/
ADD barnyard.sh /opt/
RUN chmod +x /opt/barnyard.sh
RUN wget https://github.com/shirkdog/pulledpork/archive/master.tar.gz -O pulledpork-master.tar.gz
RUN tar xzvf pulledpork-master.tar.gz
WORKDIR /opt/snort_src/pulledpork-master/
RUN cp -fv pulledpork.pl /usr/local/bin
RUN chmod +x /usr/local/bin/pulledpork.pl
RUN cp -fv etc/*.conf /etc/snort
RUN /usr/local/bin/pulledpork.pl -V
ADD pulledpork.conf /etc/snort/pulledpork.conf
RUN /usr/local/bin/pulledpork.pl -c /etc/snort/pulledpork.conf -l
RUN snort -T -c /etc/snort/snort.conf -i eth0
ADD cron /tmp/
RUN crontab /tmp/cron
ENTRYPOINT ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
