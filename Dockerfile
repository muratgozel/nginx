FROM alpine:3.13

LABEL org.opencontainers.image.source="https://github.com/muratgozel/nginx"
LABEL org.opencontainers.image.title="nginx"
LABEL org.opencontainers.image.description="Nginx server with multi host, brotli and javascript support."

ENV LANG=en_US.utf8

RUN apk add --no-cache --virtual .build-deps gcc g++ make tcl wget pkgconf \
    dpkg-dev pcre-dev openssl-dev zlib-dev && \
    apk add --no-cache bash mercurial git openssl curl ca-certificates && \
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
    hg clone http://hg.nginx.org/njs && \
    wget https://nginx.org/download/nginx-$version.tar.gz && \
    tar zxf nginx-$version.tar.gz && \
    cd nginx-$version && \
    nginx_config_args=$(nginx -V 2>&1 | tr '\n' ' ' | sed 's/^.* configure arguments: //g') && \
    ./configure "$nginx_config_args" --with-compat --add-dynamic-module=/downloads/ngx_brotli --add-dynamic-module=/downloads/njs/nginx && \
    make modules && \
    cp objs/ngx_http_brotli_filter_module.so /usr/lib/nginx/modules/ && \
    cp objs/ngx_http_brotli_static_module.so /usr/lib/nginx/modules/ && \
    cp objs/ngx_http_js_module.so /usr/lib/nginx/modules/ && \
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.backup.conf && \
    rm -rf /downloads/* && \
    cd ~ && \
    apk del --no-network .build-deps

COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./scripts /scripts

STOPSIGNAL SIGQUIT

# start database service
ENTRYPOINT ["nginx", "-c", "/etc/nginx/nginx.conf", "-g", "pid /var/run/nginx.pid; daemon off;"]
