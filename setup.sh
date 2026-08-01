#!/bin/bash

set -e

if ! kind get clusters | grep -q "^demo$"; then
    echo "Creating kind cluster..."
    kind create cluster --name demo
else
    echo "Kind cluster already exists."
fi

if ! kubectl get deployment ingress-nginx-controller -n ingress-nginx >/dev/null 2>&1; then
    echo "Installing ingress-nginx..."

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.1/deploy/static/provider/cloud/deploy.yaml

    kubectl wait \
        --namespace ingress-nginx \
        --for=condition=Available deployment/ingress-nginx-controller \
        --timeout=180s
else
    echo "Ingress controller is already installed."
fi

echo "Building Docker image..."

docker build -t enterprisebot-service:v1 ./service

echo "Loading image into kind cluster..."

kind load docker-image enterprisebot-service:v1 --name demo

if ! kubectl get namespace demo >/dev/null 2>&1; then
    echo "Creating namespace demo..."
    kubectl create namespace demo
else
    echo "Namespace demo already exists."
fi

echo "Deploying Helm chart..."

helm upgrade --install demo ./chart \
    --namespace demo

kubectl rollout status deployment/demo \
    -n demo \
    --timeout=180s

echo "Deployment completed successfully."
