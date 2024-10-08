## New Shopware-Kube Concept WiP
This concept is to test out Shopware PHP static build and compiled in application. All in a single binary.
It is based on [FrankenPHP](https://frankenphp.dev) and [static-php-cli](https://static-php.dev) projects.
Note that a static binary is built for production environments only. 
The dev version is based on `dunglas/frankenphp` image, because of inability to install xdebug in the binary version. 

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

### Configure Kubernetes cluster

Shopware cluster requires the following components to be available upfront:
* Ingress controller (e.g. NGINX Ingress Controller, Traefik or HAProxy).
* S3 compatible storage (e.g. MinIO).
* [Secret generator](https://github.com/mittwald/kubernetes-secret-generator) to automatically generate passwords.
* [Sealed secrets](https://github.com/bitnami-labs/sealed-secrets) to encrypt secrets and store encrypted in the repository.
