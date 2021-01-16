FROM centos:7
LABEL maintainer="christopher.sargent@sargentwalker.io>"
RUN yum install epel-release -y && yum update -y && yum install -y \
	httpd \
	mod_ssl \
	php \
	php-ldap \
	php-mysql \
	php-pear-CAS \
	php-pecl-xdebug \
	php-xml \
	php-xmlrpc \
	postfix \
	python-setuptools \
	tcpdump \
	which \
	&& yum clean all \
	&& rm -rf /var/cache/yum \
	&& easy_install supervisor

# install gosu
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-amd64" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-amd64.asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && rm -r /root/.gnupg/ \
    && chmod +x /usr/local/bin/gosu

COPY etc/php.d/xdebug.ini /etc/php.d/xdebug.ini
COPY src /var/www/html

# copy dependencies
RUN curl -o /tmp/spyc.tar.gz -SL "https://github.com/mustangostang/spyc/archive/0.5.1.tar.gz" \
	&& tar xvf /tmp/spyc.tar.gz -C /var/www/html/.ht-inc \
	&& rm -f /tmp/spyc.tar.gz \
	&& curl -o /tmp/dojo.tar.gz -SL "https://download.dojotoolkit.org/release-1.6.5/dojo-release-1.6.5.tar.gz" \
	&& tar xvf /tmp/dojo.tar.gz -C /var/www/html \
	&& mv /var/www/html/dojo-release-1.6.5 /var/www/html/dojo \
	&& rm -f /tmp/dojo.tar.gz

WORKDIR /var/www/html/.ht-inc
RUN ["chmod", "+x", "genkeys.sh"]
EXPOSE 80
EXPOSE 443
COPY etc/php.ini /etc/php.ini

COPY docker-entrypoint.sh /entrypoint.sh
RUN ["chmod", "+x", "/entrypoint.sh"]
COPY etc/supervisord.conf /etc/supervisord.conf
COPY etc/supervisor.d/httpd.conf /etc/supervisor.d/httpd.conf
COPY wait-for-it.sh /wait-for-it.sh
RUN ["chmod", "+x", "/wait-for-it.sh"]

# setup postfix
COPY postfix-wrapper.sh /postfix-wrapper.sh
RUN ["chmod", "+x", "/postfix-wrapper.sh"]
COPY etc/supervisor.d/postfix.conf /etc/supervisor.d/postfix.conf

WORKDIR /var/www/html
# enable mounting of vcl source code for development, logs for production and vcl-web-conf for vcl php configuration file
VOLUME [ "/var/www/html", "/var/log/httpd", "/etc/vcl-web-conf/" ]
ENTRYPOINT ["/wait-for-it.sh", "-s", "db:3306", "--", "/entrypoint.sh"]
CMD ["/wait-for-it.sh", "-s", "db:3306", "--", "/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
