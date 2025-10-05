#!/bin/bash

#. The following are not needed since the firewall is disabled
# Add PureLB library Memberlist TCP and UDP port 7934 
#sudo firewall-cmd --permanent --add-port=7934/tcp
#sudo firewall-cmd --permanent --add-port=7934/udp
#sudo firewall-cmd --reload

## Enable strict ARP and IPVS mode:
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system

kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e 's/mode: ""/mode: "ipvs"/' | \
kubectl apply -f - -n kube-system

# Prep ARP Behavior
cat <<EOF | sudo tee /etc/sysctl.d/k8s_arp.conf
net.ipv4.conf.all.arp_ignore=1
net.ipv4.conf.all.arp_announce=2

EOF
sudo sysctl --system

# Install PureLB
helm repo add purelb https://gitlab.com/api/v4/projects/20400619/packages/helm/stable
helm repo update
helm install --create-namespace --namespace=purelb purelb purelb/purelb

kubectl apply -f PureLB_Config.yaml
