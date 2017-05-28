FROM ubuntu:xenial
MAINTAINER Muhammad Salehi <salehi1994@gmail.com>
ENV DEBIAN_FRONTEND noninteractive
ENV COVERALLS_TOKEN [secure]
ENV CC gcc
ENV CXX g++
ADD sources.list /etc/apt/sources.list
RUN apt-get update && apt upgrade -y
RUN apt-get install net-tools ethtool inetutils-ping git wget build-essential libpcap-dev libpcre3-dev libdumbnet-dev bison flex zlib1g-dev liblzma-dev openssl libssl-dev libnghttp2-dev  python-pip supervisor libmysqlclient-dev mysql-client autoconf libtool -y
RUN mkdir /opt/snort_src
WORKDIR /opt/snort_src
RUN wget -c -t 0 https://snort.org/downloads/snort/daq-2.0.6.tar.gz
RUN tar -xvzf daq-2.0.6.tar.gz; cd daq-2.0.6; ./configure; make -j32; make install
RUN wget https://snort.org/downloads/snort/snort-2.9.9.0.tar.gz
RUN tar -xvzf snort-2.9.9.0.tar.gz; cd snort-2.9.9.0; ./configure --enable-sourcefire; make -j32; make install
RUN ldconfig
RUN snort -V
RUN groupadd snort
RUN useradd snort -r -s /sbin/nologin -c SNORT_IDS -g snort
RUN mkdir /etc/snort
RUN mkdir /etc/snort/rules
RUN mkdir /etc/snort/rules/iplists
RUN mkdir /etc/snort/preproc_rules
RUN mkdir /usr/local/lib/snort_dynamicrules
RUN mkdir /etc/snort/so_rules
# Create some files that stores rules and ip lists
RUN touch /etc/snort/rules/iplists/black_list.rules
RUN touch /etc/snort/rules/iplists/white_list.rules
RUN touch /etc/snort/rules/local.rules
RUN touch /etc/snort/sid-msg.map
# Create our logging directories:
RUN mkdir /var/log/snort
RUN mkdir /var/log/snort/archived_logs
# Adjust permissions:
RUN chmod -R 5775 /etc/snort
RUN chmod -R 5775 /var/log/snort
RUN chmod -R 5775 /var/log/snort/archived_logs
RUN chmod -R 5775 /etc/snort/so_rules
RUN chmod -R 5775 /usr/local/lib/snort_dynamicrules
# Change Ownership on folders:
RUN chown -R snort:snort /etc/snort
RUN chown -R snort:snort /var/log/snort
RUN chown -R snort:snort /usr/local/lib/snort_dynamicrules
WORKDIR /opt/snort_src/snort-2.9.9.0/etc/
RUN cp -fv *.conf* /etc/snort
RUN cp -fv *.map /etc/snort
RUN cp -fv *.dtd /etc/snort
WORKDIR /opt/snort_src/snort-2.9.9.0/src/dynamic-preprocessors/build/usr/local/lib/snort_dynamicpreprocessor/
RUN cp -fv * /usr/local/lib/snort_dynamicpreprocessor/
ADD snort.conf /etc/snort/snort.conf
RUN touch /etc/snort/rules/white_list.rules
RUN touch /etc/snort/rules/black_list.rules
RUN snort -T -i eth0 -c /etc/snort/snort.conf
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
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
ENTRYPOINT ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
