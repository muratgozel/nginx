FROM alpine:3.13

LABEL org.opencontainers.image.source="https://github.com/muratgozel/nginx"
LABEL org.opencontainers.image.title="nginx"
LABEL org.opencontainers.image.description="Nginx server with multi host, letsencrypt support and brotli plugin enabled."

ENV LANG=en_US.utf8
ENV NGINX_USER=nginx
ENV NGINX_USER_UID=70
ENV NGINX_USER_GID=70

RUN addgroup --gid $NGINX_USER_GID $NGINX_USER && \
    adduser --disabled-password --uid $NGINX_USER_UID --ingroup $NGINX_USER --gecos "" -s /bin/bash $NGINX_USER

RUN apk add --no-cache --virtual .build-deps gcc g++ make tcl wget pkgconf \
    dpkg-dev pcre-dev openssl-dev zlib-dev && \
    apk add --no-cache bash mercurial git openssl curl ca-certificates tzdata && \
    mkdir -p /downloads && cd /downloads && \
    # install nginx
    printf "%s%s%s\n" "http://nginx.org/packages/alpine/v" `egrep -o '^[0-9]+\.[0-9]+' /etc/alpine-release` "/main" | tee -a /etc/apk/repositories && \
    wget https://nginx.org/keys/nginx_signing.rsa.pub && \
    cp nginx_signing.rsa.pub /tmp/nginx_signing.rsa.pub && \
    openssl rsa -pubin -in /tmp/nginx_signing.rsa.pub -text -noout && \
    mv /tmp/nginx_signing.rsa.pub /etc/apk/keys/ && \
    apk --no-cache add nginx && \
    # reinstall nginx with modules
    cd /downloads && \
    version=$(nginx -v 2>&1 | sed 's/[^0-9.]*//g') && \
    git clone --recursive https://github.com/google/ngx_brotli.git && \
    wget https://nginx.org/download/nginx-$version.tar.gz && \
    tar zxf nginx-$version.tar.gz && \
    cd nginx-$version && \
    nginx_config_args=$(nginx -V 2>&1 | tr '\n' ' ' | sed 's/^.* configure arguments: //g') && \
    ./configure "$nginx_config_args" --with-compat --add-dynamic-module=/downloads/ngx_brotli && \
    make modules && \
    cp objs/ngx_http_brotli_filter_module.so /usr/lib/nginx/modules/ && \
    cp objs/ngx_http_brotli_static_module.so /usr/lib/nginx/modules/ && \
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.backup.conf && \
    rm -rf /downloads/* && \
    cd ~ && \
    apk del --no-network .build-deps && \
    apk add --no-cache gettext

COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./acme.challenge.conf /etc/nginx/acme.challenge.conf
COPY ./scripts /scripts

# configure file and folder permissions
RUN chown -R $NGINX_USER:$NGINX_USER /scripts && chmod -R 750 /scripts && \
    chown -R $NGINX_USER:$NGINX_USER /etc/nginx && chmod -R 750 /etc/nginx && \
    chown -R $NGINX_USER:$NGINX_USER /srv && chmod -R 750 /srv

STOPSIGNAL SIGQUIT

# start database service
ENTRYPOINT ["nginx", "-c", "/etc/nginx/nginx.conf", "-g", "pid /var/run/nginx.pid; daemon off;"]
