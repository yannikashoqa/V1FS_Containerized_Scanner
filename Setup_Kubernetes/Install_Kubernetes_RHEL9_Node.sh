#!/bin/bash
host_Name=$(hostname)

# Update the system
sudo dnf update -y

# Disable swap and SELinux
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
# Comment the swap entry in /etc/fstab if the previous command did not work

sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Disable the firewall.  If enabled, the File Security backend-communicator pod will keep on crashing
# Stop the firewall service
sudo systemctl stop firewalld

# Disable the firewall service to prevent it from starting at boot
sudo systemctl disable firewalld

# Add Kernel Modules and Parameters
sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

sudo tee /etc/sysctl.d/kubernetes.conf <<EOT
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOT

sudo sysctl --system

# install Containerd
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install containerd.io -y
sudo systemctl start containerd
sudo systemctl enable containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd

# Add Kubernetes Yum Repository
Version="1.35"
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v$Version/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v$Version/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

# Install Kubeadm, kubelet & kubectl
sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# Make kubelet persistant after reboot
sudo systemctl enable kubelet
