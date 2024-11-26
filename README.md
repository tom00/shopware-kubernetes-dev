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

## Setup in-cluster domain

Follow the instructions on the [Ingress DNS](https://minikube.sigs.k8s.io/docs/handbook/addons/ingress-dns).

## Build and run on Minikube using skaffold
First delete shopware-init job if exists
```shell
kubectl delete job/shopware-init -n shopware
```
Then run
```shell
skaffold run --force=true --tolerate-failures-until-deadline=tru
```
## Access MinIO GUI
```shell
kubectl port-forward -n shopware pod/minio-shopware-pool0-0 9443:9443
```
The GUI is available at https://localhost:9443

The default username and password are: `minio:minio123`.

## MinIO public readonly policy
```json
{
    "Version": "2012-10-17",
    "Statement": [

      {
        "Action": [
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ],
        "Effect": "Allow",
        "Principal": {
          "AWS": [
            "*"
          ]
        },
        "Resource": [
          "arn:aws:s3:::public"
        ],
        "Sid": ""
      },
      {
        "Action": [
          "s3:GetObject"
        ],
        "Effect": "Allow",
        "Principal": {
          "AWS": [
            "*"
          ]
        },
        "Resource": [
          "arn:aws:s3:::public/*"
        ],
        "Sid": ""
      }        
    ]
}
```

## Reverse tunnel for Xdebug using ktunnel  

```shell
ktunnel inject deployment app-server-dev 9003
```

## Port forward shopware dev server
```shell
kubectl port-forward deploy/app-server-dev -n shopware 8000:8000
```
