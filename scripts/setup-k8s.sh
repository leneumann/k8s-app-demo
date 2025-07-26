#!/bin/bash

set -e

echo "🔧 Setting up Kubernetes for local development..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if we can connect to a cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster."
    echo "Please ensure you have a local cluster running (minikube, kind, or Docker Desktop)."
    exit 1
fi

echo "✅ Connected to Kubernetes cluster:"
kubectl cluster-info

# Configure Docker to use insecure registry (for local development)
echo ""
echo "📝 Docker insecure registry configuration:"
echo "   Add 'localhost:5000' to your Docker daemon's insecure registries."
echo "   For Docker Desktop: Settings > Docker Engine > Add to 'insecure-registries'"
echo "   Example configuration:"
echo '   {'
echo '     "insecure-registries": ["localhost:5000"]'
echo '   }'
echo ""

# For minikube, enable insecure registry
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    echo "🔧 Configuring minikube for insecure registry..."
    minikube addons enable registry
    echo "✅ Minikube registry addon enabled"
fi

echo "✅ Kubernetes setup completed!"