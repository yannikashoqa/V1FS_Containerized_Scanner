#!/bin/bash

# Using Variable does not work
mytoken=$(curl -X POST "https://api.xdr.trendmicro.com/beta/fileSecurity/ctr/registration" \
 -H "Authorization: Bearer YOUR_V1_API_KEY" \
 -H "Content-Type: application/json" | jq .token)

#Strip quotes from variable
stripped=$(echo "$mytoken" | tr -d '"')

kubectl create namespace visionone-filesecurity
kubectl create secret generic token-secret --from-literal=registration-token=$stripped -n visionone-filesecurity
kubectl create secret generic device-token-secret -n visionone-filesecurity


helm repo add visionone-filesecurity https://trendmicro.github.io/visionone-file-security-helm/
helm repo update

curl -o public-key.asc https://trendmicro.github.io/visionone-file-security-helm/public-key.asc
gpg --import public-key.asc

helm install my-release visionone-filesecurity/visionone-filesecurity -n visionone-filesecurity

helm upgrade my-release visionone-filesecurity/visionone-filesecurity \
  -n visionone-filesecurity \
  -f values.yaml
