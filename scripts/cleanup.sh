#!/bin/bash

echo "🧹 Cleaning up MyApi resources..."

# Delete Kubernetes resources
echo "🗑️  Deleting Kubernetes resources..."
kubectl delete -f k8s/ --ignore-not-found=true

# Wait for pods to terminate
echo "⏳ Waiting for pods to terminate..."
kubectl wait --for=delete pod -l app=myapi --timeout=60s || true

# Stop local registry
echo "🛑 Stopping local registry..."
./scripts/registry-stop.sh

# Remove Docker images (optional)
read -p "Remove local Docker images? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Removing Docker images..."
    docker rmi localhost:5000/myapi:latest 2>/dev/null || true
    docker system prune -f
fi

echo "✅ Cleanup completed!"