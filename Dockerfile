#based on debian wheezy
FROM google/debian:wheezy
MAINTAINER gatherdigital <hello@gatherdigital.co.uk>

RUN apt-get update && \
 DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && \
 DEBIAN_FRONTEND=noninteractive apt-get -y install wget sudo supervisor pwgen apt-utils

ADD sources.list /tmp/sources.list
RUN cat /tmp/sources.list >> /etc/apt/sources.list

RUN wget -O - http://www.dotdeb.org/dotdeb.gpg | apt-key add -

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
 php5-fpm php5-cli php5-curl php5-dev php5-gd php5-imagick php5-imap \
 php5-intl php5-mcrypt php5-memcache php5-mysql php5-sqlite php5-redis \
 bzip2 unzip libxrender1 libfontconfig1 imagemagick \
 build-essential libssl-dev lynx autoconf libmagickwand-dev \
 pngnq pngcrush xvfb cabextract libfcgi0ldbl poppler-utils xfonts-75dpi \
 mysql-server-5.6 redis-server postfix

RUN apt-get -y -t wheezy-backports install libreoffice python-uno libreoffice-math

# configure apache
RUN apt-get -y install apache2-mpm-worker libapache2-mod-fastcgi
RUN a2enmod rewrite actions fastcgi alias
RUN a2dismod cgi autoindex
RUN rm /etc/apache2/sites-enabled/*
RUN rm /var/www/*

# add a success html page for testing it works
ADD success.html /var/www/success.html
RUN chown -R www-data:www-data /var/www
ADD vhost.conf /etc/apache2/sites-enabled/000-default

# set root password
# DO NOT UNCOMMENT THIS IS PRODUCTION
##RUN echo "root:root" | chpasswd

# configure mysql
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

# configure php-fpm
ADD php.ini /etc/php5/fpm/php.ini
RUN rm -r /etc/php5/cli/php.ini && ln -s /etc/php5/fpm/php.ini /etc/php5/cli/php.ini
RUN mv /etc/php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d/www.conf.dist
ADD www-data.conf /etc/php5/fpm/pool.d/www-data.conf

# configure redis
ADD redis.conf /tmp/redis.conf
RUN cat /tmp/redis.conf >> /etc/redis/redis.conf

# install tools
RUN wget "http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-wheezy-amd64.deb" -O wkhtmltopdf-0.12.deb && dpkg -i wkhtmltopdf-0.12.deb
ADD install-ghostscript.sh /tmp/install-ghostscript.sh
ADD install-ffmpeg.sh /tmp/install-ffmpeg.sh
ADD install-optimizers.sh /tmp/install-optimizers.sh
RUN chmod 755 /tmp/*.sh
RUN /tmp/install-ghostscript.sh
RUN /tmp/install-ffmpeg.sh
RUN /tmp/install-optimizers.sh

# install wkhtmltopdf
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
wkhtmltopdf openssl build-essential xorg libssl-dev xvfb

ADD wkhtmltopdf.sh /usr/local/bin/wkhtmltopdf.sh
RUN chmod a+x /usr/local/bin/wkhtmltopdf.sh

# setup startup scripts
ADD start-apache.sh /start-apache.sh
ADD start-php-fpm.sh /start-php-fpm.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# ports
EXPOSE 80

# volumes,
# uncomment if you want to add volumes to the container, for persistent storage
# VOLUME ["/var/www", "/var/lib/mysql", "/var/log"]

CMD ["/run.sh"]
