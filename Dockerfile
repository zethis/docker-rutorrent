FROM alpine:3.8

ARG BUILD_CORES
ARG MEDIAINFO_VER=0.7.99
ARG RTORRENT_VER=v0.9.8
ARG LIBTORRENT_VER=v0.13.8
ARG LIBZEN_VER=0.4.31
ARG GEOIP_VER=1.1.1

ENV UID=991 \
    GID=991 \
    WEBROOT=/ \
    PORT_RTORRENT=45000 \
    DHT_RTORRENT=off \
    DISABLE_PERM_DATA=false \
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

LABEL Description="rutorrent based on alpine" \
    tags="latest" \
    maintainer="zethis <https://github.com/zethis>" \
    libtorrent_version="${LIBTORRENT_VER}" \
    rtorrent_version="${RTORRENT_VER}"

### Download build packages
RUN echo "**** install build packages ****" && \
    apk add --no-cache --virtual=build-dependencies \
    automake \
    autoconf \
    libressl-dev \
    curl-dev \
    g++ \
    libffi-dev \
    libtool \
    make \
    ncurses-dev \
    linux-headers \
    python3-dev \
    wget

## Download run Package
RUN apk add --no-cache --upgrade \
    bind-tools \
    curl \
    fcgi \
    ffmpeg \
    geoip \
    geoip-dev \
    git \
    gzip \
    libffi \
    mediainfo \
    nginx \
    openssl \
    php7 \
    php7-fpm \
    php7-json \
    php7-opcache \
    php7-apcu \
    php7-mbstring \
    php7-ctype \
    php7-pear \
    php7-dev \
    php7-sockets \
    php7-phar \
    procps \
    python3 \
    rtorrent \
    s6 \
    screen \
    sox \
    su-exec \
    unrar \
    zip

RUN pip3 install --upgrade pip \
    && pip3 install --no-cache-dir -U \
    cfscrape \
    cloudscraper \
    cfscrape

## Compile xmlrpc-c
RUN git clone https://github.com/mirror/xmlrpc-c.git /tmp/xmlrpc-c \
    && cd /tmp/xmlrpc-c/stable \
    && ./configure \
    && make -j ${NB_CORES} \
    && make install

## Compile libtorrent needed for rtorrent
RUN git clone -b ${LIBTORRENT_VER} https://github.com/rakshasa/libtorrent.git /tmp/libtorrent \
    && cd /tmp/libtorrent \
    && ./autogen.sh \
    && ./configure \
    --disable-debug \
    --disable-instrumentation \
    && make -j ${BUILD_CORES-$(grep -c "processor" /proc/cpuinfo)} \
    && make install

## Compile rtorrent
RUN git clone -b ${RTORRENT_VER} https://github.com/rakshasa/rtorrent.git /tmp/rtorrent \
    && cd /tmp/rtorrent \
    && ./autogen.sh \
    && ./configure \
    --enable-ipv6 \
    --disable-debug \
    --with-xmlrpc-c \
    && make -j ${BUILD_CORES-$(grep -c "processor" /proc/cpuinfo)} \
    && make install

## Install Rutorrent
RUN mkdir -p /var/www \
    && git clone https://github.com/Novik/ruTorrent.git /var/www/html/rutorrent \
    && git clone https://github.com/nelu/rutorrent-thirdparty-plugins /tmp/rutorrent-thirdparty-plugins \
    && git clone https://github.com/xombiemp/rutorrentMobile.git /var/www/html/rutorrent/plugins/mobile \    
    && git clone https://github.com/Phlooo/ruTorrent-MaterialDesign.git /var/www/html/rutorrent/plugins/theme/themes/materialdesign \
    && git clone https://github.com/Micdu70/geoip2-rutorrent /var/www/html/rutorrent/plugins/geoip2 \
    && rm -rf /var/www/html/rutorrent/plugins/geoip \
    && sed -i "s/'mkdir'.*$/'mkdir',/" /tmp/rutorrent-thirdparty-plugins/filemanager/flm.class.php \
    && sed -i 's#.*/usr/bin/rar.*##' /tmp/rutorrent-thirdparty-plugins/filemanager/conf.php \
    && mv /tmp/rutorrent-thirdparty-plugins/* /var/www/html/rutorrent/plugins/ \
    && mv /var/www/html/rutorrent /var/www/html/torrent

## Install geoip files
RUN mkdir -p /usr/share/GeoIP \
    && cd /usr/share/GeoIP \
    && wget https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz \
    && wget https://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz \
    && tar xzf GeoLite2-City.tar.gz \
    && tar xzf GeoLite2-Country.tar.gz \
    && rm -f *.tar.gz \
    && mv GeoLite2-*/*.mmdb . \
    && cp *.mmdb /var/www/html/torrent/plugins/geoip2/database/ \
    && pecl install geoip-${GEOIP_VER} \
    && chmod +x /usr/lib/php7/modules/geoip.so

## cleanup
RUN strip -s /usr/local/bin/rtorrent \
    && apk del -X http://dl-cdn.alpinelinux.org/alpine/v3.8/main --no-cache ${BUILD_DEPS} cppunit-dev \
    && rm -rf /tmp/*

COPY rootfs /
VOLUME /data /config
EXPOSE 8080
RUN chmod +x /usr/local/bin/startup

ENTRYPOINT ["/usr/local/bin/startup"]
CMD ["/bin/s6-svscan", "/etc/s6.d"]
