#!/bin/bash
k8s_ip=$1
#kubeadm init --kubernetes-version=1.23.1  --apiserver-advertise-address=10.41.102.217 --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=SystemVerification
kubeadm init --kubernetes-version=1.23.1  --apiserver-advertise-address=${k8s_ip} --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=SystemVerification

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl get nodes
