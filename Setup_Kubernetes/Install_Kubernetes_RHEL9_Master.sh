#!/bin/bash
host_Name=$(hostname)

#Disable swap and SELinux
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

# Add Firewall Rules on Master and Worker Nodes
# On Master Node
#sudo firewall-cmd --permanent --add-port={6443,2379,2380,10250,10251,10252,10257,10259,179}/tcp
#sudo firewall-cmd --permanent --add-port=4789/udp
#sudo firewall-cmd --permanent --add-port=443/tcp  # Added to avoid error:  dial tcp 10.96.0.1:443: connect: no route to host
#sudo firewall-cmd --reload

# On worker Nodes
# sudo firewall-cmd --permanent --add-port={179,10250,30000-32767}/tcp
# sudo firewall-cmd --permanent --add-port=4789/udp
# sudo firewall-cmd --reload

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
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

# Install Kubeadm, kubelet & kubectl
sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# Make kubelet persistant after reboot
sudo systemctl enable kubelet

# Initialize Kubernetes Cluster (master node only)
sudo kubeadm init

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Uncoment the following command to allow pods deployed on Master node
#kubectl taint node $host_Name node-role.kubernetes.io/control-plane:NoSchedule-

# Install Pod Network Add-On (Calico): 
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.3/manifests/calico.yaml

# Install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh


# Install Metrics-Server
# Remove node label exclude-from-external-load-balancers:
#kubectl label nodes $host_Name node.kubernetes.io/exclude-from-external-load-balancers-

helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server
helm repo update

helm upgrade --install metrics-server metrics-server/metrics-server \
--namespace kube-system \
--set args="{--secure-port=10251,--kubelet-insecure-tls}" \
--set containerPort=10251
