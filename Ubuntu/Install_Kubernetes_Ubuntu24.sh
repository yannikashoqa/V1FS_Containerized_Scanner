#!/bin/bash
host_Name=$(hostname)

sudo apt install net-tools
sudo apt update
sudo apt upgrade -y

sudo swapoff -a
# Comment the swap entry in /etc/fstab 

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

sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/containerd.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update && sudo apt install containerd.io -y
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/k8s.gpg
echo 'deb [signed-by=/etc/apt/keyrings/k8s.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/k8s.list

sudo apt update
sudo apt install kubelet kubeadm kubectl -y

sudo snap install helm --classic

sudo kubeadm init --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl taint node $host_Name node-role.kubernetes.io/control-plane:NoSchedule-

####### Deploy Flannel:
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

##########################
# Install Metrics-Server
# Remove node label exclude-from-external-load-balancers:
kubectl label nodes $host_Name node.kubernetes.io/exclude-from-external-load-balancers-

kubectl create ns metrics-server
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server
helm repo update
helm install metrics-server metrics-server/metrics-server -n  metrics-server
helm upgrade metrics-server metrics-server/metrics-server --set args="{--kubelet-insecure-tls}" -n metrics-server