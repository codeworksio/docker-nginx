FROM codeworksio/ubuntu:16.04-20170614

ARG APT_PROXY
ARG APT_PROXY_SSL
ENV NGINX_VERSION="1.13.1"

RUN set -ex \
    \
    && buildDeps=' \
        build-essential \
        libpcre3-dev \
        libssl-dev \
    ' \
    && if [ -n "$APT_PROXY" ]; then echo "Acquire::http { Proxy \"http://${APT_PROXY}\"; };" > /etc/apt/apt.conf.d/00proxy; fi \
    && if [ -n "$APT_PROXY_SSL" ]; then echo "Acquire::https { Proxy \"https://${APT_PROXY_SSL}\"; };" > /etc/apt/apt.conf.d/00proxy; fi \
    && apt-get --yes update \
    && apt-get --yes install \
        $buildDeps \
    \
    && cd /tmp \
    && curl -L "https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz" -o nginx-$NGINX_VERSION.tar.gz \
    && tar -xf nginx-$NGINX_VERSION.tar.gz \
    \
    && cd /tmp/nginx-$NGINX_VERSION \
    && ./configure \
        --user=$SYSTEM_USER \
        --group=$SYSTEM_USER \
        --sbin-path=/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --http-log-path=/var/log/nginx/access.log \
        --error-log-path=/var/log/nginx/error.log \
        --with-threads \
        --with-file-aio \
        --with-http_ssl_module \
    && make \
    && make install \
    \
    && mkdir -p /usr/local/nginx /var/log/nginx \
    && chown -R $SYSTEM_USER:$SYSTEM_USER /usr/local/nginx /var/log/nginx \
    \
    && apt-get purge --yes --auto-remove $buildDeps \
    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /var/cache/apt/* \
    && rm -f /etc/apt/apt.conf.d/00proxy

ONBUILD COPY assets/ /

VOLUME [ "/var/www" ]
EXPOSE 8080 8443
CMD [ "nginx", "-g", "daemon off;" ]

### METADATA ###################################################################

ARG VERSION
ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL
LABEL \
    version=$VERSION \
    build-date=$BUILD_DATE \
    vcs-ref=$VCS_REF \
    vcs-url=$VCS_URL \
    license="MIT"
