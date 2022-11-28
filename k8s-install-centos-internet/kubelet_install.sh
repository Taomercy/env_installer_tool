#!/bin/bash
yum install -y kubelet-1.23.1 kubeadm-1.23.1 kubectl-1.23.1
systemctl enable kubelet
systemctl status kubelet
