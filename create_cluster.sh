#!/usr/bin/env bash

OS_NAME=$(uname -s | tr A-Z a-z)
ARCH=$(uname -m | tr A-Z a-z)

if [[ "${OS_NAME}" == "darwin" && "${ARCH}" != "arm64" ]]; then
	VM="hyperkit"
elif [ "${OS_NAME}" == "linux" ]; then
	VM="kvm2"
elif [[ "${OS_NAME}" == "darwin" && "${ARCH}" == "arm64" ]]; then
  VM="docker"
else
	echo "Your operating system is not yet supported."
	exit 1
fi

minikube start \
	--kubernetes-version=v1.30.0 \
	--vm-driver=${VM} \
	--cpus=2 \
	--memory=6G \
	--disk-size=30G \
	--network-plugin=cni --cni=calico
	minikube addons enable default-storageclass
	minikube addons enable storage-provisioner
	minikube addons enable metrics-server
  minikube addons enable ingress
  minikube addons enable ingress-dns