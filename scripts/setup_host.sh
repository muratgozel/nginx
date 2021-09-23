#!/usr/bin/env bash

source /scripts/functions.sh

usage() {
  cat <<USAGE >&2
usage: $0 [options]

Sets up a new nginx host.

OPTIONS:
  --help                Show this message

  --template            [Required] Nginx host template that new host will be created on.

ENV:
  NGINX_HOST            [Required] The name of the host.
  NGINX_ROOT_PARENT     [Required] The folder that will contain NGINX_HOST folder.
  LETSENCRYPT_EMAIL     Letsencrypt email.
USAGE
}

while true; do
  case "$1" in
    --help)
      usage
      exit 1
      ;;
    --template)
      if [[ -z "$2" ]]; then
        fail "Missing flag: template."
      fi
      template="$2"
      shift 2
      ;;
    --host)
      if [[ -z "$2" ]] && [[ -z $NGINX_HOST ]]; then
        fail "Missing flag: host. Or set NGINX_HOST as environment variable."
      fi
      NGINX_HOST="$2"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

conf_dir="/etc/nginx/templates"
root_dir="$NGINX_ROOT_PARENT/$NGINX_HOST/live"
NGINX_HOST_WWW=""
if ! is_subdomain $NGINX_HOST; then
  NGINX_HOST_WWW="www.$NGINX_HOST"
fi

# create host live directory
mkdir -p "$root_dir"

# create http and https conf templates
/bin/cat <<EOM >/etc/nginx/templates/$NGINX_HOST.http.conf
server {
  listen 80;
  listen [::]:80;

  include /etc/nginx/conf.d/$NGINX_HOST.conf;
}
EOM
/bin/cat <<EOM >/etc/nginx/templates/$NGINX_HOST.https.conf
server {
  listen [::]:443 ssl;
  listen 443 ssl;
  ssl_certificate /etc/letsencrypt/live/$NGINX_HOST/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/$NGINX_HOST/privkey.pem;

  include /etc/letsencrypt/nginx-ssl-options.conf;
  include /etc/nginx/conf.d/$NGINX_HOST.conf;
}

server {
  if (\$host = $NGINX_HOST) {
    return 301 https://\$host\$request_uri;
  }

  listen 80;
  listen [::]:80;
  server_name $NGINX_HOST;
  return 404;
}
EOM

# parse templates and output to nginx conf dir
envsubst '$NGINX_HOST $NGINX_ROOT_PARENT $NGINX_HOST_WWW' < /etc/nginx/templates/$template.conf > /etc/nginx/conf.d/$NGINX_HOST.conf
envsubst '$NGINX_HOST $NGINX_ROOT_PARENT $NGINX_HOST_WWW' < /etc/nginx/templates/$NGINX_HOST.http.conf > /etc/nginx/conf.d/$NGINX_HOST.http.conf

# test nginx
nginx -t 2>/dev/null > /dev/null
if [[ $? != 0 ]]; then
  fail "Nginx configuration test failed."
fi
nginx -s reload

if [[ ! -z $LETSENCRYPT_EMAIL ]]; then
  # create ssl certs
  www_cmd=""
  if ! is_subdomain $NGINX_HOST; then
    www_cmd="-d www.$NGINX_HOST"
  fi
  certbot certonly --webroot --non-interactive --redirect --agree-tos \
    --email $LETSENCRYPT_EMAIL --no-eff-email \
    -w $root_dir -d $NGINX_HOST $www_cmd

  # parse https template and output to nginx conf dir
  envsubst '$NGINX_HOST $NGINX_ROOT_PARENT $NGINX_HOST_WWW' < /etc/nginx/templates/$template.https.conf > /etc/nginx/conf.d/$NGINX_HOST.https.conf

  # test nginx
  nginx -t 2>/dev/null > /dev/null
  if [[ $? != 0 ]]; then
    fail "Nginx configuration test failed."
  fi
  nginx -s reload

  rm "/etc/nginx/conf.d/$NGINX_HOST.http.conf"
fi

success "Host ($NGINX_HOST) setup completed."
