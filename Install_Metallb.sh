#!/bin/bash

## MetalLB Install
## Enable strict ARP and IPVS mode:
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system

kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e 's/mode: ""/mode: "ipvs"/' | \
kubectl apply -f - -n kube-system

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml

while true; do
    echo "Checking MetalLB deployment Completion"
    if kubectl rollout status deployment controller -n metallb-system; then
        #echo "Break if true"
        break
    fi
done
kubectl apply -f MetalLB_Config.yaml
