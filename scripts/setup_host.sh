#!/usr/bin/env bash

# import aliases (nginx for example)
shopt -s expand_aliases && source ~/.bash_aliases

source ./setup/functions.sh

usage() {
  cat <<USAGE >&2
usage: $0 [options]

Sets up a new nginx host.

OPTIONS:
  --help                Show this message

  --host                The name of the host.

  --letsencrypt-email   The email address for acquiring ssl certs.

  --root-dir            [Default=/srv/$host/live] Hosts root dir.

  --conf-dir            [Default=nginx/conf.d-templates] Local conf dir that contains nginx configuration file templates.
USAGE
}

while true; do
  case "$1" in
    --help)
      usage
      exit 1
      ;;
    --host)
      if [[ -z "$2" ]]; then
        fail "Missing flag: host."
      fi
      host="$2"
      shift 2
      ;;
    --letsencrypt-email)
      if [[ -z "$2" ]]; then
        info "Won't install ssl certs because didn't specified letsencrypt-email flag."
      fi
      letsencrypt_email="$2"
      shift 2
      ;;
    --root-dir)
      if [[ -z "$2" ]]; then
        root_dir="/srv/$host/live"
        info "Using default root dir $root_dir"
      else
        root_dir="$2"
      fi
      shift 2
      ;;
    --conf-dir)
      if [[ -z "$2" ]]; then
        conf_dir="nginx/conf.d-templates/"
        info "Using default conf dir $conf_dir"
      else
        conf_dir="$2"
      fi
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

# create host web directory
mkdir -p "$root_dir"

# setup nginx hosts
if [[ ! -f "/etc/nginx/conf.d/acme.challenge.conf" ]]; then
  cp "${conf_dir}acme.challenge.conf" "/etc/nginx/conf.d/acme.challenge.conf"
fi
cp "${conf_dir}${host}.conf" "/etc/nginx/conf.d/${host}.conf"
cp "${conf_dir}${host}.http.conf" "/etc/nginx/conf.d/${host}.http.conf"

# test nginx
nginx -t 2>/dev/null > /dev/null
if [[ $? != 0 ]]; then
  fail "Nginx configuration test failed."
fi
nginx -s reload

if [[ ! -z $letsencrypt_email ]]; then
  # create ssl certs
  www_cmd=""
  if ! is_subdomain $host; then
    www_cmd="-d www.$host"
  fi
  certbot certonly --webroot --non-interactive --redirect --agree-tos \
    --email $letsencrypt_email --no-eff-email \
    -w /srv/$host/live -d $host $www_cmd

  # setup nginx host for https
  cp "${conf_dir}${host}.https.conf" "/etc/nginx/conf.d/$host.https.conf"

  # test nginx
  nginx -t 2>/dev/null > /dev/null
  if [[ $? != 0 ]]; then
    fail "Nginx configuration test failed."
  fi
  nginx -s reload

  rm "/etc/nginx/conf.d/$host.http.conf"
fi

success "Host ($host) setup completed."
