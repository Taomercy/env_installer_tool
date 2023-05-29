#!/bin/bash
ip=$1
pushd /etc/kubernetes/pki
    kubectl create clusterrolebinding dashboard-cluster-admin --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:kubernetes-dashboard
    kubectl config set-cluster kubernetes --certificate-authority=./ca.crt --server="https://${ip}:6443" --embed-certs=true --kubeconfig=/root/dashboard-admin.conf
    DEF_NS_ADMIN_TOKEN=` kubectl -n kubernetes-dashboard create token kubernetes-dashboard`
    echo "Token: ${DEF_NS_ADMIN_TOKEN}"
    kubectl config set-credentials dashboard-admin --token=$DEF_NS_ADMIN_TOKEN --kubeconfig=/root/dashboard-admin.conf
    kubectl config set-context dashboard-admin@kubernetes --cluster=kubernetes --user=dashboard-admin --kubeconfig=/root/dashboard-admin.conf
    kubectl config use-context dashboard-admin@kubernetes --kubeconfig=/root/dashboard-admin.conf
popd
