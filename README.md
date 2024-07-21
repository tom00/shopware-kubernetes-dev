## New Shopware-Kube Concept WiP
The concept is to test out PHP static build and compiled in application. All in a single binary.
It is based on [FrankenPHP](https://frankenphp.dev) and [static-php-cli](https://static-php.dev) projects.
Note that a binary is built for production only. The dev version is based on `dunglas/frankenphp` image.
The reason is inability to install xdebug for the binary version.

## Build

### Build dev image
```shell
docker build --target=app-dev --progress=plain -t shopware-bin-dev .
```

### Build production image
```shell
docker build --target=app-prod --progress=plain -t shopware-bin .
```

## Start

### PHP Server
Production:
```shell
docker run --rm --name=shopware-bin -p 8000:8000 shopware-bin php-server -l 0.0.0.0:8000 -a -v --no-compress 
```
Development:
```shell
docker run --rm --name=shopware-bin -p 8000:8000 shopware-bin-dev php-server -l 0.0.0.0:8000 -a -v --no-compress 
```
### PHP-cli
```shell
docker run --rm --name=shopware-bin shopware-bin php-cli bin/console
```
