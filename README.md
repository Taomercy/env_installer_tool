# k8s 安装脚本
# k8s版本 1.23.1 根目录为: k8s-1-23
# 集群架构 单master多worker

## 一、安装基础环境
### 1. 安装k8s集群前的准备工作： 
#### 脚本路径： k8s-env-install/k8s-install-script-centos/
#### （基于centos系统搭建k8s master节点）
#### 
#### 需要将hostname设置为friendly的名字，方便在集群中管理。
#### 如master节点为master, master-1, master-2。
#### worker节点可以根据供应商OS系统来命名。 如ecs-centos-1, ecs-ubuntu-2
#### 更重要的是，需要将所有worker节点的ip写入master节点 /etc/hosts文件， 在其他worker节点需要有master host ip。
#### 并配置master与worker之间免密登录。 worker之间是否需要免密不重要。

### 2. 运行脚本 (新增脚本./install.sh "[master|worker]" 调用下面三个脚本, 并且包括集群初始化)
#### a. ./k8s-env_prepare.sh
##### 执行./k8s-env_prepare.sh 它将执行以下内容：
##### 首先，它将会关闭firewall；设置内核参数；同步时间；安装基础工具包；关闭交换分区。
##### 以上任何一个步骤未完成都会导致集群初始化失败，或者出现性能问题导致的集群异常。
##### 另外，需要安装iptables, 这是针对大规模集群开发的网络转发插件。需要配置ipvs。
##### 然后，本脚本会自动生成资源清单文件，修改镜像源，从阿里云下载docker, k8s组件。
##### 因此，如果需要用Autodesk的镜像源，在脚本中需要修改。
##### 最后，脚本会关闭selinux, 然后重启。
#### b. ./docker_install.sh 安装docker， 配置docker， 配置中有个人镜像加速服务token， 可以改成Autodesk的token.
#### c. ./kubelet_install.sh 安装kubelet,kubeadm,kubectl组件
###  这三个脚本需要在master和worker顺序执行。

### 3. 初始化集群
####  ./kubeadm-init-cluster.sh ${ip} (只在master执行)
#### 可能需要修改参数： 
#### a. 检查k8s版本号，与kubelet_install.sh中一致。
#### b. 入参ip即为apiserver ip address 需要修改为master节点ip。此ip即为集群ip。
####    （若搭建多master， 此ip应为keepalived监听ip）
#### 若能正常查看node状态，即初始化成功。

### 4. 将worker节点加入集群。
#### 在master节点执行命令： kubeadm token create --print-join-command
#### 将其output 在worker节点执行， 即可加入集群。

### 5. 安装网络插件calico
#### 在master节点执行 kubectl apply -f calico.yaml,即可初始化集群网络。
#### 节点标记eg. kubectl label node ecs-centos-1 node-role.kubernetes.io/worker=worker

## 二、deploy kubernetes dashboard
##  kubectl apply -f k8s-env-install/devops-component/kubernetes-dashboard.yaml
##  execute dashboard-kubeconfig-generator.sh to generate kubeconfig file (output: /root/dashboard-admin.conf), then login dashboard with kubeconfig.
