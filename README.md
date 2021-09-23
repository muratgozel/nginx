# nginx
Nginx server with multi host, letsencrypt support and brotli plugin enabled.

## Usage
### Through docker-compose.yml
```yml
version: "3.9"

networks:
  testnet:
    driver: bridge

nginx:
  container_name: nginx01
  image: ghcr.io/muratgozel/nginx:latest
  ports:
    - 80:80
    - 443:443
  environment:
    - "NGINX_ROOT_PARENT=/srv"
    - "LETSENCRYPT_EMAIL=me@email.com"
  volumes:
    - '/etc/letsencrypt:/etc/letsencrypt:ro'
    - '/srv:/srv'
    - './templates:/etc/nginx/templates'
  extra_hosts:
    - "host.docker.internal:host-gateway"
  networks:
    - testnet
  init: true
  restart: unless-stopped
```

#### To enable ssl certs
There should be certbot installed on the host machine and configured as shown below:
```sh
# install letsencrypt/certbot
snap install core
snap refresh core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

# configure
openssl dhparam -out /etc/letsencrypt/ssl-dhparams.pem 4096
cp ./letsencrypt/nginx-ssl-options.conf /etc/letsencrypt/nginx-ssl-options.conf
```
Just remove the `/etc/letsencrypt` volume and `LETSENCRYPT_EMAIL` env var if you won't use ssl certs.

#### Setting up hosts
Initially, there is no nginx host setup inside the image. Setting up a host is done by running a shell script inside image:
```sh
docker exec nginx01 bash -c 'NGINX_HOST=mysite.com /scripts/setup_host.sh --template frontend'
```
The container should have `NGINX_ROOT_PARENT`, `NGINX_HOST` and optionally if you want ssl `LETSENCRYPT_EMAIL` environment variables in order to setup a new host. This command will generate conf files, test them, generate ssl certs (if `LETSENCRYPT_EMAIL` set) and finalize the process.

The flag `--template` is the name of the conf file inside templates folder. Script will use this file to generate valid conf files. There are two generic, nice examples for frontend and node apps.

After setup completes, `$NGINX_HOST` will be accessible through http(s). Anything you put under `$NGINX_ROOT_PARENT/$NGINX_HOST/live` directory will be accessible unless you specify something different in Location blocks.

### Review nginx.conf
An nginx.conf file is required for base nginx configuration. The important part in this file is include directives:
```conf
include /etc/nginx/conf.d/*.http.conf;
include /etc/nginx/conf.d/*.https.conf;
```
These directives used by the image when managing hosts. So keep them there. You can review and change if you want other parts of the `nginx.conf` file.

---

Version management of this repository done by [releaser](https://github.com/muratgozel/node-releaser) 🚀
