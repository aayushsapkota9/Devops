dnf install kernel-devel-$(uname -r)

modprobe br_netfilter
modprobe ip_vs
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_sh
modprobe overlay

cat > /etc/modules-load.d/kubernetes.conf << EOF
br_netfilter
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
overlay
EOF

cat > /etc/sysctl.d/kubernetes.conf << EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF


sysctl --system

# SPECIFICALLY FOR MAC
#echo "Turning off swap permanently"
#SWAP_MOUNT=$(systemctl --type swap | grep -o '[[:alnum:]-]\+\.swap')
#echo "Swap Mount = $SWAP_MOUNT"
#systemctl --type swap
#systemctl mask $SWAP_MOUNT
#echo "Done"

systemctl mask dev-sda2.swap

swapoff -a
sed -e '/swap/s/^/#/g' -i /etc/fstab

dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf makecache
dnf -y install containerd.io

sh -c "containerd config default > /etc/containerd/config.toml" ; cat /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl enable --now containerd.service

systemctl restart containerd

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

dnf makecache; dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

systemctl stop firewalld && systemctl disable firewalld

systemctl enable --now kubelet.service
