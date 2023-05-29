#!/bin/bash

# close firewall
systemctl stop firewalld ; systemctl disable firewalld

# set core parameter
modprobe br_netfilter
echo "modprobe br_netfilter" >> /etc/profile
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl -p /etc/sysctl.d/k8s.conf


# set sync time and cron task
yum install ntpdate -y
ntpdate cn.pool.ntp.org

touch /var/spool/cron/root
cat > /var/spool/cron/root << EOF
* */1 * * * /usr/sbin/ntpdate   cn.pool.ntp.org
EOF
service crond restart

# install basic package
yum install -y yum-utils device-mapper-persistent-data lvm2 wget net-tools nfs-utils lrzsz gcc gcc-c++ make cmake libxml2-devel openssl-devel curl curl-devel unzip sudo ntp libaio-devel wget vim ncurses-devel autoconf automake zlib-devel  python-devel epel-release openssh-server socat  ipvsadm conntrack ntpdate telnet ipvsadm

# swap off
swapoff -a
ID=`sed -n '/swap/=' /etc/fstab`
sed -i $ID's/^/#&/g' /etc/fstab

# install iptables
yum install iptables-services -y
service iptables stop   && systemctl disable iptables
iptables -F


# set ipvs
touch /etc/sysconfig/modules/ipvs.modules
cat > /etc/sysconfig/modules/ipvs.modules << EOF
#!/bin/bash
ipvs_modules="ip_vs ip_vs_lc ip_vs_wlc ip_vs_rr ip_vs_wrr ip_vs_lblc ip_vs_lblcr ip_vs_dh ip_vs_sh ip_vs_nq ip_vs_sed ip_vs_ftp nf_conntrack"
for kernel_module in \${ipvs_modules}; do
 /sbin/modinfo -F filename \${kernel_module} > /dev/null 2>&1
 if [ 0 -eq 0 ]; then
 /sbin/modprobe \${kernel_module}
 fi
done
EOF

chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep ip_vs


# prepare aliyun resource

#backup repos
mkdir /root/repo.bak
cd /etc/yum.repos.d/
mv * /root/repo.bak/

#prepare resource file
cat > /etc/yum.repos.d/CentOS-Base.repo << EOF
# CentOS-Base.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#
# If the mirrorlist= does not work for you, as a fall back you can try the 
# remarked out baseurl= line instead.
#
#
 
[base]
name=CentOS-$releasever - Base - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/\$releasever/os/\$basearch/
        http://mirrors.aliyuncs.com/centos/\$releasever/os/\$basearch/
        http://mirrors.cloud.aliyuncs.com/centos/\$releasever/os/\$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
 
#released updates 
[updates]
name=CentOS-\$releasever - Updates - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/\$releasever/updates/\$basearch/
        http://mirrors.aliyuncs.com/centos/\$releasever/updates/\$basearch/
        http://mirrors.cloud.aliyuncs.com/centos/\$releasever/updates/\$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
 
#additional packages that may be useful
[extras]
name=CentOS-\$releasever - Extras - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/\$releasever/extras/\$basearch/
        http://mirrors.aliyuncs.com/centos/\$releasever/extras/\$basearch/
        http://mirrors.cloud.aliyuncs.com/centos/\$releasever/extras/\$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
 
#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-\$releasever - Plus - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/\$releasever/centosplus/\$basearch/
        http://mirrors.aliyuncs.com/centos/\$releasever/centosplus/\$basearch/
        http://mirrors.cloud.aliyuncs.com/centos/\$releasever/centosplus/\$basearch/
gpgcheck=1
enabled=0
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
 
#contrib - packages by Centos Users
[contrib]
name=CentOS-\$releasever - Contrib - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/\$releasever/contrib/\$basearch/
        http://mirrors.aliyuncs.com/centos/\$releasever/contrib/\$basearch/
        http://mirrors.cloud.aliyuncs.com/centos/\$releasever/contrib/\$basearch/
gpgcheck=1
enabled=0
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
EOF

yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

touch /etc/yum.repos.d/epel.repo
cat /etc/yum.repos.d/epel.repo << EOF
[epel]
name=Extra Packages for Enterprise Linux 7 - \$basearch
#baseurl=http://download.fedoraproject.org/pub/epel/7/\$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=\$basearch&infra=\$infra&content=\$contentdir
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
[epel-debuginfo]
name=Extra Packages for Enterprise Linux 7 - $basearch - Debug
#baseurl=http://download.fedoraproject.org/pub/epel/7/\$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-7&arch=\$basearch&infra=\$infra&content=\$contentdir
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1
[epel-source]
name=Extra Packages for Enterprise Linux 7 - \$basearch - Source
#baseurl=http://download.fedoraproject.org/pub/epel/7/SRPMS
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-source-7&arch=\$basearch&infra=\$infra&content=\$contentdir
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1
EOF

touch /etc/yum.repos.d/kubernetes.repo
cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
EOF


# close selinux and reboot
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
reboot

# start to install docker kubelet
