## Shopware-Franken-Kube Concept
This concept is to test out Shopware PHP static build and compiled in application. All in a single binary.
It is based on [FrankenPHP](https://frankenphp.dev) and [static-php-cli](https://static-php.dev) projects.
Note that a static binary is built for production environments only. 
The dev version is based on `dunglas/frankenphp` image, because it is not possible to compile xdebug into the binary version.
The application is copied to a container ready to be deployed to a Kubernetes cluster.

## Build container images

### Build dev image
```shell
docker build --target=app-dev --progress=plain -t shopware-bin-dev .
```

### Build production image
```shell
docker build --target=app-prod --progress=plain -t shopware-bin .
```

## Start standalone container

### PHP Server
Production:
```shell
docker run --rm --name=shopware-bin -p 8000:8000 shopware-bin php-server -l 0.0.0.0:8000 -a -v --no-compress 
```
Development:
```shell
docker run --rm --name=shopware-bin -p 8000:8000 shopware-bin-dev php-server -l 0.0.0.0:8000 -a -v --no-compress 
```
### Run PHP-cli commands
```shell
docker run --rm --name=shopware-bin shopware-bin php-cli bin/console
```

### Configure Kubernetes cluster

Shopware cluster requires the following components to be available upfront:
* Ingress controller (e.g. NGINX Ingress Controller, Traefik or HAProxy).
* Object storage with S3 compatible API (e.g., MinIO).
* [Secret generator](https://github.com/mittwald/kubernetes-secret-generator) to automatically generate passwords.
* [Sealed secrets](https://github.com/bitnami-labs/sealed-secrets) to encrypt secrets that cannot be auto-generated, so they can be securely stored in the repository.

## Create a local Minikube Kubernetes cluster
```shell
./create_cluster.sh
```

### Setup in-cluster test domains

Add two test domains into your hosts file.

```shell
echo '127.0.0.1 media.test shopware.test' | sudo tee -a /etc/hosts
```

Get the minikube node IP address
```shell
minikube ip
```

Add .test domain into the CoreDNS config pasting the node IP address.
```shell
kubectl edit configmap coredns -n kube-system
```

Append the following into the `Corefile` and replace `192.168.49.2` with your actual IP address returned by `minikube ip`.
```
    test:53 {
        errors
        cache 30
        forward . 192.168.49.2
    }
```

## Build and run on Minikube using Skaffold
First delete shopware-init job if it exists
```shell
kubectl delete job/shopware-init -n shopware
```
Then run
```shell
skaffold run --force=true --tolerate-failures-until-deadline=true
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
## Open tunnel for storefront and media ingresses
```shell
minikube tunnel
```

## Reverse tunnel for Xdebug using ktunnel  

```shell
ktunnel inject deployment app-server-dev 9003
```

## Port forward shopware dev server
```shell
kubectl port-forward deploy/app-server-dev -n shopware 8000:8000
```
