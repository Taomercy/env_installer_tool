#!/bin/bash
kubeadm init --kubernetes-version=1.20.6  --apiserver-advertise-address=192.168.239.180  --image-repository registry.aliyuncs.com/google_containers  --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=SystemVerification

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl get nodes
