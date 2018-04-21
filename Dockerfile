FROM debian:testing

ARG TERM=linux
ARG DEBIAN_FRONTEND=noninteractive

# restyaboard version
ENV restyaboard_version=v0.6.3

# update & install package
#RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
RUN apt-get update --yes
RUN apt-get install --yes zip curl cron postgresql nginx
RUN apt-get install --yes php php-fpm php-curl php-pgsql php-imagick libapache2-mod-php
RUN echo "postfix postfix/mailname string example.com" | debconf-set-selections \
        && echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections \
        && apt-get install -y postfix

# deploy app
RUN curl -L -o /tmp/restyaboard.zip https://github.com/RestyaPlatform/board/releases/download/${restyaboard_version}/board-${restyaboard_version}.zip \
        && unzip /tmp/restyaboard.zip -d /usr/share/nginx/html \
        && rm /tmp/restyaboard.zip

# setting app
WORKDIR /usr/share/nginx/html
RUN cp -R media /tmp/ \
        && cp restyaboard.conf /etc/nginx/conf.d \
        && sed -i 's/^.*listen.mode = 0660$/listen.mode = 0660/' /etc/php/7.2/fpm/pool.d/www.conf \
        && sed -i 's|^.*fastcgi_pass.*$|fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;|' /etc/nginx/conf.d/restyaboard.conf \
        && sed -i -e "/fastcgi_pass/a fastcgi_param HTTPS 'off';" /etc/nginx/conf.d/restyaboard.conf

RUN sed -i 's/include \/etc\/nginx\/sites-enabled/#include \/etc\/nginx\/sites-enables/' /etc/nginx/nginx.conf \
    && chown -R www-data.www-data /usr/share/nginx
# volume
VOLUME /usr/share/nginx/html/media

# entry point
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh", "start"]
CMD []
#ENTRYPOINT []
#CMD ["tail", "-f", "/dev/null"]

# expose port
EXPOSE 80
