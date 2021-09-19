# nginx
Nginx server with multi host, letsencrypt, brotli and javascript support.

This is a docker hub repository that installs custom nginx with brotli and javascript modules. It also supports multi host configuration.

## Usage
### nginx.conf
An nginx.conf file is required for base nginx configuration. The important part in this file is the include directives:
```conf
include /etc/nginx/conf.d/*.http.conf;
include /etc/nginx/conf.d/*.https.conf;
```
You shouldn't change those lines to keep multip host functionality.

### conf.d-templates
This folder contains all of the host files. There are conventions when adding hosts:
1. An acme.challenge.conf file will be included automatically when you install ssl certs. You don't need to change anything in this file.
2. Each host has at least 2 conf files which are $host.conf and $host.http.conf. There should be also $host.https.conf file if you install ssl certs.

You will most likely want to change lines that contain `example.com` and location blocks.

### Letsencrypt
Certbot is required if you use https and needs to be installed on the host machine.

### Using through docker-compose.yml file
```yml
version: "3.9"

networks:
  testnet:
    driver: bridge

nginx:
  container_name: nginx01
  image: muratgozel/nginx:latest
  user: root
  build:
    context: ./nginx
  ports:
    - 80:80
    - 443:443
  volumes:
    - '/etc/letsencrypt:/etc/letsencrypt'
    - '/srv:/srv'
  extra_hosts:
    - "host.docker.internal:host-gateway"
  networks:
    - testnet
  restart: unless-stopped
```

---

Version management of this repository done by [releaser](https://github.com/muratgozel/node-releaser) 🚀
