#!/bin/bash

set -e

echo "🚀 Deploying MyApi to Kubernetes..."

# Apply Kubernetes manifests
echo "📄 Creating namespace..."
kubectl apply -f k8s/namespace.yaml

echo "📄 Applying ConfigMap..."
kubectl apply -f k8s/configmap.yaml

echo "📄 Applying Deployment..."
kubectl apply -f k8s/deployment.yaml

echo "📄 Applying Service..."
kubectl apply -f k8s/service.yaml

echo "📄 Applying Ingress..."
kubectl apply -f k8s/ingress.yaml

echo "📄 Applying Horizontal Pod Autoscaler..."
kubectl apply -f k8s/hpa.yaml

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/myapi-deployment -n k8s-app-demo --timeout=300s

# Show deployment status
echo "📊 Deployment status:"
kubectl get pods -l app=myapi -n k8s-app-demo
kubectl get services -l app=myapi -n k8s-app-demo
kubectl get hpa myapi-hpa -n k8s-app-demo

echo "✅ Deployment completed successfully!"

# Show access information
echo ""
echo "🌐 Access Information:"
echo "   NodePort: http://localhost:30081"
echo "   If using minikube: minikube service myapi-service --url"
echo "   Health Check: http://localhost:30081/health"
echo "   Swagger UI: http://localhost:30081/swagger"