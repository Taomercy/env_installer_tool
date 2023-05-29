#!/bin/bash
apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2
if [[ $? != 0 ]];then
    sudo rm /var/lib/apt/lists/lock
    sudo rm /var/cache/apt/archives/lock
    sudo rm /var/lib/dpkg/lock*
    sudo dpkg --configure -a
    sudo apt update
    apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2
fi

# Install docker
curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/ \
  $(lsb_release -cs) \
  stable"

sudo apt-get install docker-ce docker-ce-cli containerd.io -y
cat <<EOF | tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl restart docker
systemctl enable --now docker
docker ps -a

# Config containerd
cat > /etc/containerd/config.toml <<EOF
[plugins."io.containerd.grpc.v1.cri"]
systemd_cgroup = true
EOF
systemctl restart containerd


# Install k8s 1.27.1

apt-get update && apt-get install -y apt-transport-https curl
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://mirrors.ustc.edu.cn/kubernetes/apt kubernetes-xenial main
EOF

apt-get update > souce_output.log
if [[ $? != 0 ]];then    
    log="souce_output.log"
    pubkey_regex="NO_PUBKEY ([A-F0-9]+)"
    
    while IFS= read -r line; do
      if [[ $line =~ $pubkey_regex ]]; then
        pubkey=${BASH_REMATCH[1]}
        echo "Importing pubkey: $pubkey"
        sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $pubkey
      fi
    done < "$log"

    apt-get update && apt-get install -y apt-transport-https curl
fi

rm -rf souce_output.log

apt-get install -y kubelet=1.27.1-00 kubeadm=1.27.1-00 kubectl=1.27.1-00

apt-mark hold kubelet kubeadm kubectl 

swapoff -a

echo """
If master, init cluster
kubeadm init --apiserver-advertise-address \${master_ip} --image-repository registry.cn-hangzhou.aliyuncs.com/google_containers --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=SystemVerification --cri-socket unix:///var/run/cri-dockerd.sock
mkdir -p \$HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config
sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config

If worker, join cluster
master: kubeadm token create --print-join-command > join_cmd
worker: \${join_cmd}
master: kubectl label node \${node-name} node-role.kubernetes.io/worker=worker
"""
