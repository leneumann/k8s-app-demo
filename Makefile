.PHONY: help setup build deploy undeploy logs clean status test dev

# Default target
help: ## Show this help message
	@echo "MyApi - Local Development Makefile"
	@echo "=================================="
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Setup local development environment (registry + k8s + metrics)
	@echo "🚀 Setting up local development environment..."
	@./scripts/setup-k8s.sh
	@./scripts/registry-start.sh
	@./scripts/fix-metrics-server.sh
	@echo "✅ Setup complete!"

fix-metrics: ## Fix metrics server for HPA (if having scaling issues)
	@./scripts/fix-metrics-server.sh

build: ## Build and push Docker image to local registry
	@echo "🔨 Building application..."
	@./scripts/build.sh

deploy: ## Deploy application to Kubernetes
	@echo "🚀 Deploying to Kubernetes..."
	@./scripts/deploy.sh

undeploy: ## Remove application from Kubernetes
	@echo "🗑️ Undeploying from Kubernetes..."
	@kubectl delete namespace k8s-app-demo --ignore-not-found=true
	@echo "✅ Application undeployed successfully!"

redeploy: build deploy ## Build and deploy in one command

logs: ## Show application logs
	@./scripts/logs.sh

logs-follow: ## Follow application logs
	@./scripts/logs.sh -f

status: ## Show deployment status
	@echo "📊 Deployment Status:"
	@echo "===================="
	@kubectl get pods -l app=myapi -n k8s-app-demo -o wide || echo "No pods found"
	@echo ""
	@kubectl get services -l app=myapi -n k8s-app-demo || echo "No services found"
	@echo ""
	@kubectl get hpa myapi-hpa -n k8s-app-demo || echo "No HPA found"
	@echo ""
	@echo "🔍 Registry Status:"
	@curl -s http://localhost:5000/v2/_catalog | jq '.' 2>/dev/null || echo "Registry not available"

test: ## Test the deployed application
	@echo "🧪 Testing deployed application..."
	@echo "Health check:"
	@curl -f http://localhost:30081/health || echo "Health check failed"
	@echo ""
	@echo "API test:"
	@curl -f http://localhost:30081/api/users || echo "API test failed"

load-test: ## Generate load to trigger HPA scaling
	@./scripts/load-test.sh

load-test-long: ## Generate load for 5 minutes (longer test)
	@./scripts/load-test.sh 300 15

load-test-heavy: ## Generate heavy load with more concurrent requests
	@./scripts/load-test.sh 180 20

clean: ## Clean up all resources
	@./scripts/cleanup.sh

dev: setup build deploy status ## Full development workflow: setup, build, deploy, and show status

# Docker commands
docker-build: ## Build Docker image locally
	@docker build -t myapi:latest .

docker-run: ## Run Docker container locally
	@docker run -d -p 8080:8080 --name myapi-local myapi:latest
	@echo "Application running at http://localhost:8080"

docker-stop: ## Stop local Docker container
	@docker stop myapi-local || true
	@docker rm myapi-local || true

# Registry commands
registry-start: ## Start local Docker registry only
	@./scripts/registry-start.sh

registry-stop: ## Stop local Docker registry only
	@./scripts/registry-stop.sh

registry-ui: ## Open registry browser (if available)
	@echo "Registry catalog: http://localhost:5000/v2/_catalog"
	@curl -s http://localhost:5000/v2/_catalog | jq '.'

# Kubernetes commands
k8s-pods: ## Show all pods
	@kubectl get pods -l app=myapi -n k8s-app-demo

k8s-services: ## Show all services
	@kubectl get services -l app=myapi -n k8s-app-demo

k8s-hpa: ## Show horizontal pod autoscaler status
	@kubectl get hpa myapi-hpa -n k8s-app-demo

k8s-watch-scaling: ## Watch HPA and pod scaling in real-time
	@./scripts/watch-scaling.sh

k8s-logs: ## Show logs from all pods
	@./scripts/logs.sh

k8s-describe: ## Describe deployment
	@kubectl describe deployment myapi-deployment -n k8s-app-demo

k8s-port-forward: ## Port forward to a pod (8080:8080)
	@echo "Port forwarding to pod on localhost:8080..."
	@kubectl port-forward deployment/myapi-deployment 8080:8080 -n k8s-app-demo