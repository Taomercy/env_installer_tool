#!/bin/bash
role=${1:-"worker"}
./k8s-env_prepare.sh && ./docker_install.sh && ./kubelet_install.sh

if [ "$role" = "master" ]; then
  k8s_ip=$2
  ./kubeadm-init-cluster.sh "${k8s_ip}"
fi

